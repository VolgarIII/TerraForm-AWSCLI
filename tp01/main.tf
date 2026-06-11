data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_pet" "suffix" {
  length    = 2
  separator = "-"
}

locals {
  name_prefix = "${var.project}-${var.environment}"
  bucket_name = "${local.name_prefix}-${data.aws_caller_identity.current.account_id}-${random_pet.suffix.id}"
}

resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name

  tags = merge(var.tags, {
    Owner = var.owner
    Name  = local.bucket_name
  })
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "force_tls" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket     = aws_s3_bucket.main.id
  policy     = data.aws_iam_policy_document.force_tls.json
  depends_on = [aws_s3_bucket_public_access_block.main]
}
