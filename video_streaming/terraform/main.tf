# Placeholder for video streaming infrastructure
# Requires MediaLive and MediaPackage setup

resource "aws_s3_bucket" "video_source" {
  bucket = "${var.project_name}-source-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

resource "aws_s3_bucket" "video_output" {
  bucket = "${var.project_name}-output-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

resource "aws_cloudfront_distribution" "video" {
  enabled = true
  origin {
    domain_name = aws_s3_bucket.video_output.bucket_regional_domain_name
    origin_id   = "S3-video"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.video.cloudfront_access_identity_path
    }
  }
  default_cache_behavior {
    target_origin_id       = "S3-video"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }
  restrictions {
    geo_restriction { restriction_type = "none" }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "video" {
  comment = "Video streaming OAI"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
