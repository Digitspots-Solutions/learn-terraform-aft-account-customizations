# Portal Automation Role - allows portal to deploy infrastructure in this account
# NOTE: This role is created by the account-provisioning-customizations pipeline
# We import it here to manage the policy attachment only

# Import the existing role (created by provisioning customizations)
data "aws_iam_role" "portal_automation" {
  name = "PortalAutomationRole"
}

# Ensure AdministratorAccess is attached
# This is idempotent - if already attached, Terraform will not re-attach
resource "aws_iam_role_policy_attachment" "portal_automation_admin" {
  role       = data.aws_iam_role.portal_automation.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "portal_automation_role_arn" {
  value       = data.aws_iam_role.portal_automation.arn
  description = "ARN of the Portal Automation Role"
}
