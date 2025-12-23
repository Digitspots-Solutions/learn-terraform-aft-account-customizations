resource "aws_cloudformation_stack" "data_analytics" {
  name         = "data-analytics"
  template_url = "https://s3.amazonaws.com/aft-customizations-${data.aws_caller_identity.current.account_id}/templates/data_analytics.yaml"

  capabilities = ["CAPABILITY_IAM"]
}

data "aws_caller_identity" "current" {}
