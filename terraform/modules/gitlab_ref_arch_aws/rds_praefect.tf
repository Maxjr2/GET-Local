locals {
  rds_praefect_postgres_create = var.rds_praefect_postgres_instance_type != ""

  rds_praefect_postgres_subnet_ids    = local.backend_subnet_ids != null ? local.backend_subnet_ids : slice(tolist(local.default_subnet_ids), 0, var.rds_praefect_postgres_default_subnet_count)
  rds_praefect_postgres_major_version = floor(var.rds_praefect_postgres_version)

  # https://docs.gitlab.com/ee/administration/troubleshooting/postgresql.html#database-deadlocks
  rds_praefect_postgres_default_params = { password_encryption = "scram-sha-256", log_min_duration_statement = 1000, idle_in_transaction_session_timeout = 60000, statement_timeout = 15000, deadlock_timeout = 5000 }
}

data "aws_kms_key" "aws_praefect_rds" {
  count = local.rds_praefect_postgres_create && var.rds_praefect_postgres_kms_key_arn == null && var.default_kms_key_arn == null ? 1 : 0

  key_id = "alias/aws/rds"
}

resource "aws_db_subnet_group" "gitlab_praefect" {
  count      = local.rds_praefect_postgres_create ? 1 : 0
  name       = "${var.prefix}-praefect-rds-subnet-group"
  subnet_ids = local.rds_praefect_postgres_subnet_ids

  tags = {
    Name = "${var.prefix}-praefect-rds-subnet-group"
  }
}

resource "aws_db_parameter_group" "gitlab_praefect" {
  count = local.rds_praefect_postgres_create ? 1 : 0

  name_prefix = "${var.prefix}-rds-praefect-pg${local.rds_praefect_postgres_major_version}-"
  family      = "postgres${local.rds_praefect_postgres_major_version}"

  dynamic "parameter" {
    for_each = merge(local.rds_praefect_postgres_default_params, var.rds_praefect_postgres_params)
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "gitlab_praefect" {
  count = local.rds_praefect_postgres_create ? 1 : 0

  identifier     = "${var.prefix}-rds-praefect"
  engine         = "postgres"
  engine_version = var.rds_praefect_postgres_version
  instance_class = "db.${var.rds_praefect_postgres_instance_type}"
  multi_az       = var.rds_praefect_postgres_multi_az
  iops           = var.rds_praefect_postgres_iops
  storage_type   = var.rds_praefect_postgres_storage_type

  db_name  = var.rds_praefect_postgres_database_name
  port     = var.rds_praefect_postgres_port
  username = var.rds_praefect_postgres_username
  password = var.rds_praefect_postgres_password

  iam_database_authentication_enabled = true

  db_subnet_group_name = aws_db_subnet_group.gitlab_praefect[0].name
  vpc_security_group_ids = [
    aws_security_group.gitlab_rds_praefect[0].id
  ]

  parameter_group_name = aws_db_parameter_group.gitlab_praefect[0].name
  apply_immediately    = true

  allocated_storage     = var.rds_praefect_postgres_allocated_storage
  max_allocated_storage = var.rds_praefect_postgres_max_allocated_storage
  storage_encrypted     = true
  kms_key_id            = coalesce(var.rds_praefect_postgres_kms_key_arn, var.default_kms_key_arn, try(data.aws_kms_key.aws_praefect_rds[0].arn, null))

  backup_window           = var.rds_praefect_postgres_backup_window
  backup_retention_period = var.rds_praefect_postgres_backup_retention_period
  maintenance_window      = var.rds_praefect_postgres_maintenance_window

  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = var.rds_praefect_postgres_auto_minor_version_upgrade

  skip_final_snapshot = true

  delete_automated_backups = var.rds_praefect_postgres_delete_automated_backups

  copy_tags_to_snapshot = true
  tags                  = var.rds_praefect_postgres_tags
}

resource "aws_db_instance" "gitlab_praefect_read_replica" {
  count = local.rds_praefect_postgres_create ? var.rds_praefect_postgres_read_replica_count : 0

  identifier     = "${format("%.38s", var.prefix)}-rds-praefect-read-rep-${count.index + 1}"
  instance_class = aws_db_instance.gitlab_praefect[0].instance_class
  iops           = aws_db_instance.gitlab_praefect[0].iops
  storage_type   = aws_db_instance.gitlab_praefect[0].storage_type

  port     = var.rds_praefect_postgres_read_replica_port
  multi_az = var.rds_praefect_postgres_read_replica_multi_az

  vpc_security_group_ids = [
    aws_security_group.gitlab_rds_praefect[0].id
  ]

  iam_database_authentication_enabled = aws_db_instance.gitlab_praefect[0].iam_database_authentication_enabled

  parameter_group_name = aws_db_parameter_group.gitlab_praefect[0].name
  replicate_source_db  = aws_db_instance.gitlab_praefect[0].identifier
  apply_immediately    = true

  max_allocated_storage = aws_db_instance.gitlab_praefect[0].max_allocated_storage
  storage_encrypted     = true
  kms_key_id            = aws_db_instance.gitlab_praefect[0].kms_key_id

  allow_major_version_upgrade = aws_db_instance.gitlab_praefect[0].allow_major_version_upgrade
  auto_minor_version_upgrade  = aws_db_instance.gitlab_praefect[0].auto_minor_version_upgrade

  skip_final_snapshot     = true
  copy_tags_to_snapshot   = true
  backup_retention_period = 0

  tags = var.rds_praefect_postgres_tags
}

output "rds_praefect_postgres_connection" {
  value = {
    "rds_praefect_host"               = try(aws_db_instance.gitlab_praefect[0].address, "")
    "rds_praefect_port"               = try(aws_db_instance.gitlab_praefect[0].port, "")
    "rds_praefect_database_name"      = try(aws_db_instance.gitlab_praefect[0].db_name, "")
    "rds_praefect_database_username"  = try(aws_db_instance.gitlab_praefect[0].username, "")
    "rds_praefect_database_arn"       = try(aws_db_instance.gitlab_praefect[0].arn, "")
    "rds_praefect_kms_key_arn"        = try(aws_db_instance.gitlab_praefect[0].kms_key_id, "")
    "rds_praefect_version"            = try(aws_db_instance.gitlab_praefect[0].engine_version_actual, "")
    "rds_praefect_read_replica_hosts" = try(aws_db_instance.gitlab_praefect_read_replica[*].address, "")
  }
}
