resource "aws_s3_bucket" "gitlab_object_storage_buckets" {
  for_each      = toset(var.object_storage_buckets)
  bucket        = "${var.object_storage_prefix != null ? var.object_storage_prefix : var.prefix}-${each.value}"
  force_destroy = var.object_storage_force_destroy

  lifecycle {
    ignore_changes = [
      replication_configuration
    ]
  }

  tags = var.object_storage_tags
}

resource "aws_s3_bucket_versioning" "gitlab_object_storage_buckets" {
  for_each = aws_s3_bucket.gitlab_object_storage_buckets

  bucket = each.value.id

  versioning_configuration {
    status = var.object_storage_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "gitlab_object_storage_buckets" {
  for_each = aws_s3_bucket.gitlab_object_storage_buckets

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.object_storage_kms_key_arn != null ? var.object_storage_kms_key_arn : var.default_kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "gitlab_object_storage_buckets" {
  for_each = var.object_storage_block_public_access ? aws_s3_bucket.gitlab_object_storage_buckets : tomap({})

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Policies
locals {
  gitlab_s3_policy_create          = length(var.object_storage_buckets) > 0
  gitlab_s3_backups_policy_create  = length(var.object_storage_buckets) > 0 && contains(var.object_storage_buckets, "backups")
  gitlab_s3_registry_policy_create = length(var.object_storage_buckets) > 0 && contains(var.object_storage_buckets, "registry")
  gitlab_s3_kms_policy_create      = length(var.object_storage_buckets) > 0 && (var.object_storage_kms_key_arn != null || var.default_kms_key_arn != null)
  # Special permission required for Geo to process HEAD requests
  # https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html
  gitlab_s3_list_bucket_permission = var.geo_site != null ? ["s3:ListBucket"] : []
}

## S3 access policy for all buckets except registry and backups (covered by separate policies)
resource "aws_iam_policy" "gitlab_s3_policy" {
  count = local.gitlab_s3_policy_create ? 1 : 0
  name  = "${var.prefix}-s3-policy"
  path  = var.default_iam_identifier_path

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = setunion(
          [
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject",
          ],
          local.gitlab_s3_list_bucket_permission,
        )
        Effect   = "Allow"
        Resource = concat([for k, v in aws_s3_bucket.gitlab_object_storage_buckets : v.arn if !contains(["registry", "backups"], k)], [for k, v in aws_s3_bucket.gitlab_object_storage_buckets : "${v.arn}/*" if !contains(["registry", "backups"], k)])
      }
    ]
  })
}

## S3 access policy for backups bucket
resource "aws_iam_policy" "gitlab_s3_backups_policy" {
  count = local.gitlab_s3_backups_policy_create ? 1 : 0
  name  = "${var.prefix}-s3-backups-policy"
  path  = var.default_iam_identifier_path

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = [aws_s3_bucket.gitlab_object_storage_buckets["backups"].arn, "${aws_s3_bucket.gitlab_object_storage_buckets["backups"].arn}/*"]
      }
    ]
  })
}

## S3 access policy for registry bucket
resource "aws_iam_policy" "gitlab_s3_registry_policy" {
  count = local.gitlab_s3_registry_policy_create ? 1 : 0
  name  = "${var.prefix}-s3-registry-policy"
  path  = var.default_iam_identifier_path

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Docker Registry S3 bucket requires specific permissions
      # https://docs.docker.com/registry/storage-drivers/s3/#s3-permission-scopes
      {
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.gitlab_object_storage_buckets["registry"].arn
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.gitlab_object_storage_buckets["registry"].arn}/*"
      },
    ]
  })
}

## S3 access policy for KMS usage with buckets if specified
resource "aws_iam_policy" "gitlab_s3_kms_policy" {
  count = local.gitlab_s3_kms_policy_create ? 1 : 0
  name  = "${var.prefix}-s3-kms-policy"
  path  = var.default_iam_identifier_path

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect   = "Allow"
        Resource = var.object_storage_kms_key_arn != null ? var.object_storage_kms_key_arn : var.default_kms_key_arn
      }
    ]
  })
}

# Replication (Geo)

locals {
  enable_object_storage_replication = var.object_storage_destination_buckets != null
  object_storage_replications_list = var.object_storage_destination_buckets != null ? flatten([
    for key, values in aws_s3_bucket.gitlab_object_storage_buckets : {
      (key) = {
        destination = lookup(var.object_storage_destination_buckets, key, null)
        source      = values.arn
      }
    }
  ]) : null

  object_storage_replications_map = local.object_storage_replications_list != null ? {
    for item in local.object_storage_replications_list :
    keys(item)[0] => values(item)[0]
  } : null
}

resource "aws_iam_role" "gitlab_s3_replication_role" {
  count = local.enable_object_storage_replication ? 1 : 0
  name  = "${var.prefix}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })

  path                 = var.default_iam_identifier_path
  permissions_boundary = var.default_iam_permissions_boundary_arn
}

resource "aws_iam_policy" "gitlab_s3_replication_policy" {
  count = local.enable_object_storage_replication ? 1 : 0
  name  = "${var.prefix}-s3-replication-policy"
  path  = var.default_iam_identifier_path

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          for key, values in aws_s3_bucket.gitlab_object_storage_buckets : values.arn
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ],
        Effect = "Allow",
        Resource = [
          for key, values in aws_s3_bucket.gitlab_object_storage_buckets : "${values.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ],
        Effect = "Allow",
        Resource = [
          for key, value in var.object_storage_destination_buckets : "${value}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gitlab_s3_replication_attachment" {
  count = local.enable_object_storage_replication ? 1 : 0

  role       = aws_iam_role.gitlab_s3_replication_role[0].name
  policy_arn = aws_iam_policy.gitlab_s3_replication_policy[0].arn
}

resource "aws_s3_bucket_replication_configuration" "gitlab_s3_replication_configuration" {
  for_each = local.object_storage_replications_list != null ? local.object_storage_replications_map : tomap({})

  role   = aws_iam_role.gitlab_s3_replication_role[0].arn
  bucket = split(":::", each.value.source)[1]

  rule {
    id       = "${var.prefix}-${each.value.source}-replication"
    priority = 0

    status = "Enabled"

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket = each.value.destination

      encryption_configuration {
        replica_kms_key_id = var.object_storage_replica_kms_key_id
      }
    }
  }
}

data "aws_kms_key" "aws_s3" {
  key_id = "alias/aws/s3"
}

output "object_storage_buckets" {
  value = {
    for k, v in aws_s3_bucket.gitlab_object_storage_buckets : k => v.arn
  }
}

output "object_storage_kms_key_arn" {
  value = coalesce(var.object_storage_kms_key_arn, var.default_kms_key_arn, try(data.aws_kms_key.aws_s3.arn, null))
}
