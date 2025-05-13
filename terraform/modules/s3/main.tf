data "aws_caller_identity" "current" {}

locals {
  buckets = {
    bronze = "${var.bucket_prefix}-bronze-${data.aws_caller_identity.current.account_id}"
    silver = "${var.bucket_prefix}-silver-${data.aws_caller_identity.current.account_id}"
    gold   = "${var.bucket_prefix}-gold-${data.aws_caller_identity.current.account_id}"
  }
}

resource "aws_s3_bucket" "this" {
  for_each      = local.buckets
  bucket        = each.value
  force_destroy = true

  tags = merge(var.tags, { "tier" = each.key })
}

resource "aws_s3_bucket_versioning" "bronze" {
  for_each = { for k, v in aws_s3_bucket.this : k => v if k == "bronze" }

  bucket = each.value.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
