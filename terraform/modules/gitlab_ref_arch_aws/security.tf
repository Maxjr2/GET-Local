locals {
  gitlab_shell_ssh_port = var.haproxy_external_node_count > 0 && var.gitlab_shell_ssh_port == null ? 2222 : (var.external_ssh_port != 2222 ? var.external_ssh_port : var.gitlab_shell_ssh_port)
}

resource "aws_key_pair" "ssh_key" {
  count = var.ssh_public_key != null ? 1 : 0

  key_name   = "${var.prefix}-ssh-key"
  public_key = var.ssh_public_key
}

data "aws_vpc" "selected" {
  id = coalesce(local.vpc_id, local.default_vpc_id)
}

# Internal
resource "aws_security_group" "gitlab_internal_networking" {
  # Allows for machine internal connections as well as outgoing internet access
  # Avoid changes that cause replacement due to EKS Cluster issue
  name   = "${var.prefix}-internal-networking"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    description = "Open internal networking for VMs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  dynamic "ingress" {
    for_each = range(length(var.internal_allowed_ingress_security_group_ids) > 0 ? 1 : 0)

    content {
      description     = "Open internal networking from configured Security Groups"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      security_groups = var.internal_allowed_ingress_security_group_ids
    }
  }

  dynamic "ingress" {
    for_each = range(var.peer_vpc_cidr != null ? 1 : 0)

    content {
      description = "Open internal peer networking for VMs"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [var.peer_vpc_cidr]
    }
  }

  egress {
    description = "Open internet access for VMs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-internal-networking"
  }
}

# External
resource "aws_security_group" "gitlab_external_ssh" {
  # Create only if no created or existing private subnets and if a SSH key has been passed
  count = (var.subnet_priv_count == 0 && var.subnet_priv_ids == null) && var.ssh_public_key != null ? 1 : 0

  name_prefix = "${var.prefix}-external-ssh-"
  vpc_id      = data.aws_vpc.selected.id

  # kics: Terraform AWS - Security groups allow ingress from 0.0.0.0:0, Sensitive Port Is Exposed To Entire Network - False positive, source CIDR is configurable
  # kics-scan ignore-block
  ingress {
    description = "Enable SSH access for VMs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = coalescelist(var.external_ssh_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  tags = {
    Name = "${var.prefix}-external-ssh"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "gitlab_external_git_ssh" {
  count = local.gitlab_shell_ssh_port != null ? 1 : 0

  name_prefix = "${var.prefix}-external-git-ssh-"
  vpc_id      = data.aws_vpc.selected.id

  # kics: Terraform AWS - Security groups allow ingress from 0.0.0.0:0 - False positive, source CIDR is configurable
  # kics-scan ignore-block
  ingress {
    description = "External Git SSH access for ${var.prefix}"
    from_port   = local.gitlab_shell_ssh_port
    to_port     = local.gitlab_shell_ssh_port
    protocol    = "tcp"
    cidr_blocks = coalescelist(var.ssh_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  tags = {
    Name = "${var.prefix}-external-git-ssh"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# kics: Terraform AWS - Security Group Rules Without Description - False positive due to issue https://github.com/Checkmarx/kics/issues/4691
# kics: Terraform AWS - HTTP Port Open - Context dependent, only allowed on HAProxy External
# kics-scan ignore-block
resource "aws_security_group" "gitlab_external_http_https" {
  count = (var.haproxy_external_node_count + var.monitor_node_count + length(var.gitlab_rails_elastic_ip_allocation_ids)) > 0 ? 1 : 0

  name_prefix = "${var.prefix}-external-http-https-"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "Enable HTTP access for select VMs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  ingress {
    description = "Enable HTTPS access for select VMs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  tags = {
    Name = "${var.prefix}-external-http-https"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Services Security Groups
## AWS RDS
### GitLab
resource "aws_security_group" "gitlab_rds" {
  count = local.rds_postgres_create ? 1 : 0

  name_prefix = "${var.prefix}-rds-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-rds"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_rds_internal_networking" {
  count = local.rds_postgres_create ? 1 : 0

  security_group_id = aws_security_group.gitlab_rds[0].id

  description = "Enable internal access to RDS from ${aws_security_group.gitlab_internal_networking.name} security group"
  from_port   = var.rds_postgres_port
  to_port     = var.rds_postgres_port
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.gitlab_internal_networking.id

  tags = {
    Name = "${var.prefix}-rds-internal-networking"
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_rds_cidr" {
  for_each = local.rds_postgres_create ? toset(var.rds_postgres_allowed_ingress_cidr_blocks) : []

  security_group_id = aws_security_group.gitlab_rds[0].id

  description = "Enable access to RDS from CIDR block ${each.key}"
  from_port   = var.rds_postgres_port
  to_port     = var.rds_postgres_port
  ip_protocol = "tcp"

  cidr_ipv4 = each.key

  tags = {
    Name = "${var.prefix}-rds-cidr-${each.key}"
  }
}

### Praefect
resource "aws_security_group" "gitlab_rds_praefect" {
  count = local.rds_praefect_postgres_create ? 1 : 0

  name_prefix = "${var.prefix}-rds-praefect-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-rds-praefect"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_rds_praefect_internal_networking" {
  count = local.rds_praefect_postgres_create ? 1 : 0

  security_group_id = aws_security_group.gitlab_rds_praefect[0].id

  description = "Enable internal access to Praefect RDS from ${aws_security_group.gitlab_internal_networking.name} security group"
  from_port   = var.rds_praefect_postgres_port
  to_port     = var.rds_praefect_postgres_port
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.gitlab_internal_networking.id

  tags = {
    Name = "${var.prefix}-rds-praefect-internal-networking"
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_rds_praefect_cidr" {
  for_each = local.rds_praefect_postgres_create ? toset(var.rds_praefect_postgres_allowed_ingress_cidr_blocks) : []

  security_group_id = aws_security_group.gitlab_rds_praefect[0].id

  description = "Enable access to Praefect RDS from CIDR block ${each.key}"
  from_port   = var.rds_praefect_postgres_port
  to_port     = var.rds_praefect_postgres_port
  ip_protocol = "tcp"

  cidr_ipv4 = each.key

  tags = {
    Name = "${var.prefix}-rds-praefect-cidr-${each.key}"
  }
}

### Geo Tracking
resource "aws_security_group" "gitlab_rds_geo_tracking" {
  count = local.rds_geo_tracking_postgres_create ? 1 : 0

  name_prefix = "${var.prefix}-rds-geo-tracking-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-rds-geo-tracking"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_rds_geo_tracking_internal_networking" {
  count = local.rds_geo_tracking_postgres_create ? 1 : 0

  security_group_id = aws_security_group.gitlab_rds_geo_tracking[0].id

  description = "Enable internal access to Geo Tracking RDS from ${aws_security_group.gitlab_internal_networking.name} security group"
  from_port   = var.rds_geo_tracking_postgres_port
  to_port     = var.rds_geo_tracking_postgres_port
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.gitlab_internal_networking.id

  tags = {
    Name = "${var.prefix}-rds-geo-tracking-internal-networking"
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_rds_geo_tracking_cidr" {
  for_each = local.rds_geo_tracking_postgres_create ? toset(var.rds_geo_tracking_postgres_allowed_ingress_cidr_blocks) : []

  security_group_id = aws_security_group.gitlab_rds_geo_tracking[0].id

  description = "Enable access to Geo Tracking RDS from CIDR block ${each.key}"
  from_port   = var.rds_geo_tracking_postgres_port
  to_port     = var.rds_geo_tracking_postgres_port
  ip_protocol = "tcp"

  cidr_ipv4 = each.key

  tags = {
    Name = "${var.prefix}-rds-geo-tracking-cidr-${each.key}"
  }
}

## AWS Elasticache
### Redis (Combined)
resource "aws_security_group" "gitlab_elasticache_redis" {
  count = min(var.elasticache_redis_node_count, 1)

  name_prefix = "${var.prefix}-elasticache-redis-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-elasticache-redis"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_elasticache_redis_internal_networking" {
  count = min(var.elasticache_redis_node_count, 1)

  security_group_id = aws_security_group.gitlab_elasticache_redis[0].id

  description = "Enable internal access to ElastiCache Redis from ${aws_security_group.gitlab_internal_networking.name} security group"
  from_port   = var.elasticache_redis_port
  to_port     = var.elasticache_redis_port
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.gitlab_internal_networking.id

  tags = {
    Name = "${var.prefix}-elasticache-redis-internal-networking"
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_elasticache_redis_cidr" {
  for_each = var.elasticache_redis_node_count > 0 ? toset(var.elasticache_redis_allowed_ingress_cidr_blocks) : []

  security_group_id = aws_security_group.gitlab_elasticache_redis[0].id

  description = "Enable access to ElastiCache Redis from CIDR block ${each.key}"
  from_port   = var.elasticache_redis_port
  to_port     = var.elasticache_redis_port
  ip_protocol = "tcp"

  cidr_ipv4 = each.key

  tags = {
    Name = "${var.prefix}-elasticache-redis-cidr-${each.key}"
  }
}

### Redis Cache
locals {
  elasticache_redis_cache_allowed_ingress_cidr_blocks = coalesce(var.elasticache_redis_cache_allowed_ingress_cidr_blocks, var.elasticache_redis_allowed_ingress_cidr_blocks)
}

resource "aws_security_group" "gitlab_elasticache_redis_cache" {
  count = min(var.elasticache_redis_cache_node_count, 1)

  name_prefix = "${var.prefix}-elasticache-redis-cache-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-elasticache-redis-cache"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_elasticache_redis_cache_internal_networking" {
  count = min(var.elasticache_redis_cache_node_count, 1)

  security_group_id = aws_security_group.gitlab_elasticache_redis_cache[0].id

  description = "Enable internal access to ElastiCache Redis Cache from ${aws_security_group.gitlab_internal_networking.name} security group"
  from_port   = local.elasticache_redis_cache_port
  to_port     = local.elasticache_redis_cache_port
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.gitlab_internal_networking.id

  tags = {
    Name = "${var.prefix}-elasticache-redis-cache-internal-networking"
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_elasticache_redis_cache_cidr" {
  for_each = var.elasticache_redis_cache_node_count > 0 ? toset(local.elasticache_redis_cache_allowed_ingress_cidr_blocks) : []

  security_group_id = aws_security_group.gitlab_elasticache_redis_cache[0].id

  description = "Enable access to ElastiCache Redis Cache from CIDR block ${each.key}"
  from_port   = local.elasticache_redis_cache_port
  to_port     = local.elasticache_redis_cache_port
  ip_protocol = "tcp"

  cidr_ipv4 = each.key

  tags = {
    Name = "${var.prefix}-elasticache-redis-cache-cidr-${each.key}"
  }
}

### Redis Persistent
locals {
  elasticache_redis_persistent_allowed_ingress_cidr_blocks = coalesce(var.elasticache_redis_persistent_allowed_ingress_cidr_blocks, var.elasticache_redis_allowed_ingress_cidr_blocks)
}

resource "aws_security_group" "gitlab_elasticache_redis_persistent" {
  count = min(var.elasticache_redis_persistent_node_count, 1)

  name_prefix = "${var.prefix}-elasticache-redis-persistent-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-elasticache-redis-persistent"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_elasticache_redis_persistent_internal_networking" {
  count = min(var.elasticache_redis_persistent_node_count, 1)

  security_group_id = aws_security_group.gitlab_elasticache_redis_persistent[0].id

  description = "Enable internal access to ElastiCache Redis Persistent from ${aws_security_group.gitlab_internal_networking.name} security group"
  from_port   = local.elasticache_redis_persistent_port
  to_port     = local.elasticache_redis_persistent_port
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.gitlab_internal_networking.id

  tags = {
    Name = "${var.prefix}-elasticache-redis-persistent-internal-networking"
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_elasticache_redis_persistent_cidr" {
  for_each = var.elasticache_redis_persistent_node_count > 0 ? toset(local.elasticache_redis_persistent_allowed_ingress_cidr_blocks) : []

  security_group_id = aws_security_group.gitlab_elasticache_redis_persistent[0].id

  description = "Enable access to ElastiCache Redis Persistent from CIDR block ${each.key}"
  from_port   = local.elasticache_redis_persistent_port
  to_port     = local.elasticache_redis_persistent_port
  ip_protocol = "tcp"

  cidr_ipv4 = each.key

  tags = {
    Name = "${var.prefix}-elasticache-redis-persistent-cidr-${each.key}"
  }
}

## AWS OpenSearch
resource "aws_security_group" "gitlab_opensearch_service" {
  count = min(var.opensearch_service_node_count, 1)

  name_prefix = "${var.prefix}-opensearch-service-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-opensearch-service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_opensearch_service_internal_networking" {
  count = min(var.opensearch_service_node_count, 1)

  security_group_id = aws_security_group.gitlab_opensearch_service[0].id

  description = "Enable internal access to AWS OpenSearch from ${aws_security_group.gitlab_internal_networking.name} security group"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  referenced_security_group_id = aws_security_group.gitlab_internal_networking.id

  tags = {
    Name = "${var.prefix}-opensearch-service-internal-networking"
  }
}

resource "aws_vpc_security_group_ingress_rule" "gitlab_opensearch_service_cidr" {
  for_each = var.opensearch_service_node_count > 0 ? toset(var.opensearch_service_allowed_ingress_cidr_blocks) : []

  security_group_id = aws_security_group.gitlab_opensearch_service[0].id

  description = "Enable access to AWS OpenSearch from CIDR block ${each.key}"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  cidr_ipv4 = each.key

  tags = {
    Name = "${var.prefix}-opensearch-service-cidr-${each.key}"
  }
}
