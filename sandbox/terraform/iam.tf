# Portal Automation Role
# =====================
# This role allows the Opportunity Portal to deploy infrastructure in this account.
# It may already exist (created by StackSet) or need to be created by AFT.
# We check first and only create if it doesn't exist.

locals {
  portal_account_id = "929557547206"
  external_id       = "opportunity-portal-automation"
  role_name         = "PortalAutomationRole"
}

# Check if role already exists
data "external" "check_portal_role" {
  program = ["bash", "-c", <<-EOF
    if aws iam get-role --role-name ${local.role_name} 2>/dev/null >&2; then
      echo '{"exists": "true"}'
    else
      echo '{"exists": "false"}'
    fi
  EOF
  ]
}

# Only create the role if it doesn't already exist
resource "aws_iam_role" "portal_automation" {
  count = data.external.check_portal_role.result.exists == "false" ? 1 : 0

  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${local.portal_account_id}:role/opportunity-portal-dev-lambda-role",
            "arn:aws:iam::${local.portal_account_id}:role/opportunity-portal-dev-codebuild-terraform"
          ]
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = local.external_id
          }
        }
      }
    ]
  })

  tags = {
    ManagedBy = "OpportunityPortal"
    Purpose   = "InfrastructureDeployment"
  }
}

# Attach AdministratorAccess only if we created the role
resource "aws_iam_role_policy_attachment" "portal_automation_admin" {
  count = data.external.check_portal_role.result.exists == "false" ? 1 : 0

  role       = aws_iam_role.portal_automation[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Get the role ARN regardless of how it was created
data "aws_iam_role" "portal_automation_existing" {
  count = data.external.check_portal_role.result.exists == "true" ? 1 : 0
  name  = local.role_name
}

output "portal_automation_role_arn" {
  description = "ARN of the Portal Automation Role"
  value = (
    data.external.check_portal_role.result.exists == "true"
    ? data.aws_iam_role.portal_automation_existing[0].arn
    : aws_iam_role.portal_automation[0].arn
  )
}

output "portal_automation_role_created_by" {
  description = "How the role was provisioned"
  value = data.external.check_portal_role.result.exists == "true" ? "StackSet/Pre-existing" : "AFT-Customizations"
}
