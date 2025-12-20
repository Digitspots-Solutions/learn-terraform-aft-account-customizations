resource "aws_cloudformation_stack" "simple_storage_cdn" {
  name         = "simple-storage-cdn"
  template_url = "https://s3.amazonaws.com/aft-customizations-${data.aws_caller_identity.current.account_id}/templates/simple_storage_cdn.yaml"
  
  parameters = {
    PriceClass = var.price_class
  }

  capabilities = ["CAPABILITY_IAM"]
}

data "aws_caller_identity" "current" {}
