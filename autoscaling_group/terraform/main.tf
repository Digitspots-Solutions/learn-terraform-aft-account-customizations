# Auto Scaling Group Stack - terraform-aws-modules/autoscaling/aws wrapper

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-state-${data.aws_caller_identity.current.account_id}"
    key    = "vpc_basic/${data.aws_region.current.name}/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  vpc_id      = try(data.terraform_remote_state.vpc.outputs.vpc_id, "")
  subnet_ids  = try(data.terraform_remote_state.vpc.outputs.private_subnet_ids, [])
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 8.0"

  name = "${local.name_prefix}-asg"

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  vpc_zone_identifier = local.subnet_ids

  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  security_groups = [aws_security_group.asg.id]

  tags = { Environment = var.environment, Stack = "autoscaling_group", ManagedBy = "OpportunityPortal" }
}

resource "aws_security_group" "asg" {
  name   = "${local.name_prefix}-asg-sg"
  vpc_id = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-asg-sg" }
}

output "asg_name" { value = module.asg.autoscaling_group_name }
output "asg_arn" { value = module.asg.autoscaling_group_arn }

