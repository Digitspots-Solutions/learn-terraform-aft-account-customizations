# Serverless API Stack - Lambda + API Gateway + DynamoDB
# Using native Terraform instead of CloudFormation

# DynamoDB Table
resource "aws_dynamodb_table" "api_table" {
  name         = "${var.api_name}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "${var.api_name}-table"
  }
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_exec" {
  name = "${var.api_name}-lambda-exec-${data.aws_region.current.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  role = aws_iam_role.lambda_exec.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Scan",
        "dynamodb:Query"
      ]
      Resource = aws_dynamodb_table.api_table.arn
    }]
  })
}

# Lambda Function
resource "aws_lambda_function" "api" {
  filename      = "${path.module}/lambda.zip"
  function_name = "${var.api_name}-handler"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.api_table.name
    }
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "api" {
  name          = var.api_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.api.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = var.stage_name
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Create a simple Lambda deployment package
data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"

  source {
    content  = <<-EOT
      exports.handler = async (event) => {
        return {
          statusCode: 200,
          body: JSON.stringify({message: 'Hello from serverless API!'})
        };
      };
    EOT
    filename = "index.js"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}