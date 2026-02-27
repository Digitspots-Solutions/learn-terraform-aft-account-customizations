# Portal Automation Role - allows portal to deploy infrastructure in this account
# This role is CREATED by AFT when the account is FIRST provisioned
# DO NOT change this to a data source - new accounts need this role created!
# The "sandbox" folder should NOT be a deployable stack from the portal

resource "aws_iam_role" "portal_automation" {
  name = "PortalAutomationRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::929557547206:role/opportunity-portal-dev-lambda-role",
            "arn:aws:iam::929557547206:role/opportunity-portal-dev-codebuild-terraform"
          ]
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "opportunity-portal-automation"
          }
        }
      }
    ]
  })
}

# Attach AdministratorAccess for full infrastructure deployment capabilities
resource "aws_iam_role_policy_attachment" "portal_automation_admin" {
  role       = aws_iam_role.portal_automation.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "portal_automation_role_arn" {
  value       = aws_iam_role.portal_automation.arn
  description = "ARN of the Portal Automation Role"
}
