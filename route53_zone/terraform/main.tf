# Route53 Zone Stack
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Managed by OpportunityPortal"

  tags = {
    Environment = var.environment
    Stack       = "route53_zone"
    ManagedBy   = "OpportunityPortal"
  }
}

output "zone_id" { value = aws_route53_zone.main.zone_id }
output "name_servers" { value = aws_route53_zone.main.name_servers }

