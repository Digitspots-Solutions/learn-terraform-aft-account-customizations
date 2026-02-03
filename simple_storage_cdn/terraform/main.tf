# Simple Storage + CDN Stack - S3 + CloudFront
# Using Origin Access Identity (OAI) for compatibility with AWS Provider 3.x

# S3 Bucket for storage
resource "aws_s3_bucket" "storage" {
  bucket = "simple-storage-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Identity (OAI) for S3 access
resource "aws_cloudfront_origin_access_identity" "storage" {
  comment = "OAI for simple-storage CDN"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = var.price_class

  origin {
    domain_name = aws_s3_bucket.storage.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.storage.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.storage.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.storage.id}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "simple-storage-cdn"
  }
}

# S3 Bucket Policy for CloudFront OAI
resource "aws_s3_bucket_policy" "storage" {
  bucket = aws_s3_bucket.storage.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontOAI"
      Effect = "Allow"
      Principal = {
        AWS = aws_cloudfront_origin_access_identity.storage.iam_arn
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.storage.arn}/*"
    }]
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}