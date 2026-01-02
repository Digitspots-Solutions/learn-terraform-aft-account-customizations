resource "aws_sagemaker_notebook_instance" "main" {
  name          = "${var.notebook_name}-${data.aws_region.current.name}"
  instance_type = var.instance_type
  role_arn      = aws_iam_role.sagemaker.arn
}

resource "aws_iam_role" "sagemaker" {
  name = "${var.notebook_name}-sagemaker-${data.aws_region.current.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "sagemaker.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker" {
  role       = aws_iam_role.sagemaker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_s3_bucket" "ml_data" {
  bucket = "${var.notebook_name}-ml-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
