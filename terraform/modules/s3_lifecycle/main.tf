variable "bucket_name" {
  type = string
}

resource "aws_s3_bucket_lifecycle_configuration" "lc" {
  bucket = var.bucket_name

  rule {
    id     = "to-ia-then-glacier"
    status = "Enabled"

    # Apply to the whole bucket
    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 3650
    }
  }
}
