resource "aws_s3_bucket_server_side_encryption_configuration" "encryptionconfig" {
  bucket = var.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_acl" "bucketacl" {
  bucket = var.bucket
  acl    = "private"
}

resource "aws_s3_bucket_ownership_controls" "ownershipcontrol" {
  bucket = var.bucket

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "publicaccesscontrol"{
  bucket = var.bucket

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
