resource "aws_cloudformation_stack" "container_platform" {
  name         = "container-platform"
  template_url = "https://s3.amazonaws.com/aft-customizations-${data.aws_caller_identity.current.account_id}/templates/container_platform.yaml"
  
  parameters = {
    VpcStackName = var.vpc_stack_name
  }

  capabilities = ["CAPABILITY_IAM"]
}

data "aws_caller_identity" "current" {}
