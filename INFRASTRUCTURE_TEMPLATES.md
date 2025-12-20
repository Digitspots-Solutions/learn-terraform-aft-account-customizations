# AFT Account Customizations - Infrastructure Templates

This repository contains infrastructure customization templates that can be deployed to AWS accounts via the Opportunity Account Portal.

## Available Templates

### 1. Baseline Networking
**Directory:** `baseline_networking/`
- VPC with 2 availability zones
- Public and private subnets
- NAT gateway for private subnet internet access
- Security groups for web, app, and database tiers
- VPC Flow Logs

### 2. Simple Storage & CDN
**Directory:** `simple_storage_cdn/`
- S3 buckets for website content, user uploads, and backups
- CloudFront distribution with HTTPS redirect
- Lifecycle policies for cost optimization
- Origin Access Identity for secure S3 access

### 3. Security Baseline
**Directory:** `security_baseline/`
- CloudTrail with multi-region logging
- GuardDuty detector
- Security Hub
- AWS Config
- SNS topic for security alerts
- EventBridge rules for GuardDuty findings

### 4. Serverless API
**Directory:** `serverless_api/`
- API Gateway REST API
- Lambda function with Python runtime
- DynamoDB table with on-demand billing
- CloudWatch Logs integration

### 5. Container Platform
**Directory:** `container_platform/`
- ECS Fargate cluster
- Application Load Balancer
- ECR repository with image scanning
- Auto-scaling configuration
- **Requires:** baseline_networking stack

### 6. Data Analytics
**Directory:** `data_analytics/`
- S3 data lake (raw, processed, results buckets)
- Glue database and crawler
- Glue ETL job
- Athena workgroup

## Structure

Each customization follows the AFT standard structure:

```
<stack-name>/
├── terraform/
│   ├── main.tf              # CloudFormation stack deployment
│   ├── variables.tf         # Configurable parameters
│   ├── versions.tf          # Terraform version constraints
│   ├── backend.jinja        # AFT backend configuration
│   └── aft-providers.jinja  # AFT provider configuration
└── api_helpers/
    ├── pre-api-helpers.sh   # Pre-deployment scripts
    ├── post-api-helpers.sh  # Post-deployment scripts
    └── python/
        └── requirements.txt # Python dependencies
```

## CloudFormation Templates

The actual CloudFormation templates are stored in the portal repository at:
`opportunity-account-portal/infrastructure/templates/`

These templates are uploaded to an S3 bucket and referenced by the Terraform configurations.

## Deployment via Portal

Users can deploy these stacks through the portal's "Customize Account" page:

1. Select Organization → OU → Account
2. Choose one or more infrastructure stacks
3. Submit deployment request
4. Portal triggers AFT customization pipeline

## Prerequisites

### For New Accounts
The `PortalAutomationRole` is automatically created during account provisioning via the `learn-terraform-aft-account-provisioning-customizations` repository.

### For Existing Accounts
Deploy the `PortalAutomationRole` using one of these methods:
- **AFT Provisioning:** Update account request to trigger provisioning customizations
- **Manual CLI:** Use AWS CLI to create the role
- **StackSet:** Deploy role to multiple accounts at once

See `AUTOMATION_ROLE_SETUP.md` in the portal repository for details.

## Adding New Templates

1. Create new directory: `<stack-name>/`
2. Copy structure from existing template (e.g., `baseline_networking/`)
3. Create CloudFormation template in portal repo: `infrastructure/templates/<stack-name>.yaml`
4. Update `main.tf` to reference your template
5. Add stack to portal's `list_stacks.py` handler
6. Commit and push to trigger AFT pipeline

## Testing

Test customizations in a sandbox account before deploying to production:

```bash
cd <stack-name>/terraform
terraform init
terraform plan
terraform apply
```

## Support

For issues or questions, contact the platform team or open an issue in the portal repository.
