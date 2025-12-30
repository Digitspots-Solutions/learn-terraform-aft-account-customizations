# Web Starter - Minimal cost web hosting (~$15-25/mo)
# Single t3.micro instance behind an ALB
# Perfect for: Personal sites, blogs, small business websites

locals {
  app_name_unique = "${var.app_name}-${data.aws_caller_identity.current.account_id}"
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "aft-backend-${data.aws_caller_identity.current.account_id}"
    key    = "baseline_networking/terraform.tfstate"
    region = "us-east-1"
  }
}

# Single EC2 instance (no auto-scaling for cost savings)
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.network.outputs.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Welcome to ${var.app_name}</h1><p>Powered by Web Starter</p>" > /var/www/html/index.html
  EOF
  )
  
  tags = {
    Name = "${local.app_name_unique}-web"
    Tier = "starter"
  }
}

resource "aws_security_group" "alb" {
  name   = "${local.app_name_unique}-alb"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${local.app_name_unique}-alb-sg"
  }
}

resource "aws_security_group" "web" {
  name   = "${local.app_name_unique}-web"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${local.app_name_unique}-web-sg"
  }
}

resource "aws_lb" "web" {
  name               = "${local.app_name_unique}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.terraform_remote_state.network.outputs.public_subnet_ids
  
  tags = {
    Name = "${local.app_name_unique}-alb"
    Tier = "starter"
  }
}

resource "aws_lb_target_group" "web" {
  name     = "${local.app_name_unique}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id
  
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_caller_identity" "current" {}

output "alb_dns_name" {
  value       = aws_lb.web.dns_name
  description = "Application Load Balancer DNS name"
}

output "instance_id" {
  value       = aws_instance.web.id
  description = "Web server instance ID"
}

