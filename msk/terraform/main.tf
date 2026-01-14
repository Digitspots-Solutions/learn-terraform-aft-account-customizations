# MSK (Managed Streaming for Apache Kafka) Stack
# Managed Kafka cluster for event streaming
#
# Features:
# - Multi-AZ deployment
# - Encrypted at rest and in transit
# - CloudWatch monitoring
# - Auto-scaling storage

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  # Backend configured by buildspec.yml at runtime
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get VPC outputs from vpc_production stack (MSK needs production VPC)
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-state-${data.aws_caller_identity.current.account_id}"
    key    = "vpc_production/${data.aws_region.current.name}/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  name_prefix = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  vpc_id      = try(data.terraform_remote_state.vpc.outputs.vpc_id, "")
  subnet_ids  = try(data.terraform_remote_state.vpc.outputs.private_subnet_ids, [])
  vpc_cidr    = try(data.terraform_remote_state.vpc.outputs.vpc_cidr, "10.0.0.0/16")
}

# Security group for MSK
resource "aws_security_group" "msk" {
  name        = "${local.name_prefix}-msk-sg"
  description = "Security group for MSK cluster"
  vpc_id      = local.vpc_id

  # Kafka broker ports
  ingress {
    description = "Kafka plaintext from VPC"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  ingress {
    description = "Kafka TLS from VPC"
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  ingress {
    description = "Kafka IAM auth from VPC"
    from_port   = 9098
    to_port     = 9098
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  # ZooKeeper port
  ingress {
    description = "ZooKeeper from VPC"
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-msk-sg"
    Environment = var.environment
    Stack       = "msk"
    ManagedBy   = "OpportunityPortal"
  }
}

# KMS key for encryption
resource "aws_kms_key" "msk" {
  description             = "KMS key for MSK cluster encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${local.name_prefix}-msk-key"
    Environment = var.environment
    Stack       = "msk"
    ManagedBy   = "OpportunityPortal"
  }
}

# CloudWatch log group for broker logs
resource "aws_cloudwatch_log_group" "msk" {
  name              = "/aws/msk/${local.name_prefix}-cluster"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Stack       = "msk"
    ManagedBy   = "OpportunityPortal"
  }
}

# MSK Configuration
resource "aws_msk_configuration" "main" {
  kafka_versions = [var.kafka_version]
  name           = "${local.name_prefix}-msk-config"

  server_properties = <<PROPERTIES
auto.create.topics.enable=true
default.replication.factor=3
min.insync.replicas=2
num.io.threads=8
num.network.threads=5
num.partitions=3
num.replica.fetchers=2
replica.lag.time.max.ms=30000
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
socket.send.buffer.bytes=102400
unclean.leader.election.enable=false
zookeeper.session.timeout.ms=18000
PROPERTIES
}

# MSK Cluster
resource "aws_msk_cluster" "main" {
  cluster_name           = "${local.name_prefix}-cluster"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.broker_count

  broker_node_group_info {
    instance_type   = var.instance_type
    client_subnets  = slice(local.subnet_ids, 0, min(var.broker_count, length(local.subnet_ids)))
    security_groups = [aws_security_group.msk.id]

    storage_info {
      ebs_storage_info {
        volume_size = var.ebs_volume_size
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.main.arn
    revision = aws_msk_configuration.main.latest_revision
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.msk.arn
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  client_authentication {
    sasl {
      iam   = true
      scram = false
    }
    unauthenticated = false
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  tags = {
    Name        = "${local.name_prefix}-msk-cluster"
    Environment = var.environment
    Stack       = "msk"
    ManagedBy   = "OpportunityPortal"
  }
}

# Outputs
output "cluster_arn" {
  value       = aws_msk_cluster.main.arn
  description = "MSK cluster ARN"
}

output "bootstrap_brokers_tls" {
  value       = aws_msk_cluster.main.bootstrap_brokers_tls
  description = "TLS connection string for Kafka brokers"
}

output "bootstrap_brokers_iam" {
  value       = aws_msk_cluster.main.bootstrap_brokers_sasl_iam
  description = "IAM auth connection string for Kafka brokers"
}

output "zookeeper_connect_string" {
  value       = aws_msk_cluster.main.zookeeper_connect_string
  description = "ZooKeeper connection string"
}

output "security_group_id" {
  value       = aws_security_group.msk.id
  description = "Security group ID for MSK"
}

output "kms_key_arn" {
  value       = aws_kms_key.msk.arn
  description = "KMS key ARN used for encryption"
}

