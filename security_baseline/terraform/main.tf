resource "aws_cloudformation_stack" "security_baseline" {
  name         = "security-baseline"
  template_url = "https://s3.amazonaws.com/aft-customizations-${data.aws_caller_identity.current.account_id}/templates/security_baseline.yaml"
  
  capabilities = ["CAPABILITY_IAM"]
}

data "aws_caller_identity" "current" {}
