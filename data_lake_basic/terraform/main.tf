resource "aws_s3_bucket" "raw" {
  bucket = "${var.project_name}-raw-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

resource "aws_s3_bucket" "processed" {
  bucket = "${var.project_name}-processed-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.project_name}-athena-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

resource "aws_glue_catalog_database" "main" {
  name = "${var.project_name}_db_${data.aws_region.current.name}"
}

resource "aws_iam_role" "glue" {
  name = "${var.project_name}-glue-${data.aws_region.current.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_s3" {
  role = aws_iam_role.glue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:*"]
      Resource = [
        aws_s3_bucket.raw.arn,
        "${aws_s3_bucket.raw.arn}/*",
        aws_s3_bucket.processed.arn,
        "${aws_s3_bucket.processed.arn}/*"
      ]
    }]
  })
}

# Wait for IAM role to propagate (AWS eventual consistency)
resource "time_sleep" "wait_for_glue_role" {
  depends_on = [
    aws_iam_role_policy_attachment.glue,
    aws_iam_role_policy.glue_s3
  ]
  create_duration = "10s"
}

resource "aws_glue_crawler" "main" {
  name          = "${var.project_name}-crawler-${data.aws_region.current.name}"
  role          = aws_iam_role.glue.arn
  database_name = aws_glue_catalog_database.main.name
  s3_target {
    path = "s3://${aws_s3_bucket.raw.bucket}/"
  }
  
  depends_on = [time_sleep.wait_for_glue_role]
}

resource "aws_athena_workgroup" "main" {
  name = "${var.project_name}-${data.aws_region.current.name}"
  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
