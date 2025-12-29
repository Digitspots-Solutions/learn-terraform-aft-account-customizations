# Portal Automation Role - allows portal to deploy infrastructure in this account
# This role is CREATED by AFT account-customizations, so we just reference it here
# to avoid "EntityAlreadyExists" errors when the portal deploys this stack

data "aws_iam_role" "portal_automation" {
  name = "PortalAutomationRole"
}

# AdministratorAccess should already be attached by AFT
# This is idempotent - Terraform will not fail if already attached
resource "aws_iam_role_policy_attachment" "portal_automation_admin" {
  role       = data.aws_iam_role.portal_automation.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "portal_automation_role_arn" {
  value       = data.aws_iam_role.portal_automation.arn
  description = "ARN of the Portal Automation Role"
}
