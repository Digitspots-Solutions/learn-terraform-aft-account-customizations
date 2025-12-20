resource "aws_cloudformation_stack" "baseline_networking" {
  name         = "baseline-networking"
  template_url = "https://s3.amazonaws.com/aft-customizations-${data.aws_caller_identity.current.account_id}/templates/baseline_networking.yaml"
  
  parameters = {
    VpcCidr = var.vpc_cidr
  }

  capabilities = ["CAPABILITY_IAM"]
}

data "aws_caller_identity" "current" {}
