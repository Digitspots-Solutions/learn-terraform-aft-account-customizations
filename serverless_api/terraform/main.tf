resource "aws_cloudformation_stack" "serverless_api" {
  name         = "serverless-api"
  template_url = "https://s3.amazonaws.com/aft-customizations-${data.aws_caller_identity.current.account_id}/templates/serverless_api.yaml"
  
  parameters = {
    StageName = var.stage_name
  }

  capabilities = ["CAPABILITY_IAM"]
}

data "aws_caller_identity" "current" {}
