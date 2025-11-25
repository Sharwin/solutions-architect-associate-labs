terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# SNS Topic for Order Notifications
resource "aws_sns_topic" "order_notifications" {
  name              = "ecommerce-order-notifications"
  display_name      = "E-Commerce Order Notifications"
  
  tags = {
    Environment = "Lab"
    Purpose     = "SNS-Education"
  }
}

# SQS Queue for Warehouse Processing
resource "aws_sqs_queue" "warehouse_queue" {
  name                      = "warehouse-order-processing"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600  # 4 days
  
  tags = {
    Environment = "Lab"
    Purpose     = "SNS-Education"
  }
}

# Dead Letter Queue for failed warehouse messages
resource "aws_sqs_queue" "warehouse_dlq" {
  name                      = "warehouse-order-processing-dlq"
  message_retention_seconds = 1209600  # 14 days
  
  tags = {
    Environment = "Lab"
    Purpose     = "SNS-Education"
  }
}

# Redrive policy for warehouse queue
resource "aws_sqs_queue_redrive_policy" "warehouse_queue" {
  queue_url = aws_sqs_queue.warehouse_queue.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.warehouse_dlq.arn
    maxReceiveCount     = 3
  })
}

# Lambda function for Analytics Processing
resource "aws_lambda_function" "analytics_processor" {
  filename         = "analytics_processor.zip"
  function_name    = "sns-analytics-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "analytics_processor.lambda_handler"
  runtime         = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tags = {
    Environment = "Lab"
    Purpose     = "SNS-Education"
  }
}

# Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "analytics_processor.py"
  output_path = "analytics_processor.zip"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "sns-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = "Lab"
    Purpose     = "SNS-Education"
  }
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "sns-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# SNS Subscription: Email (for order confirmation)
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.order_notifications.arn
  protocol  = "email"
  endpoint  = var.email_endpoint
  
  # Filter policy: Only send order confirmation emails
  filter_policy = jsonencode({
    message_type = ["order_confirmation"]
  })
}

# SNS Subscription: SMS (for order tracking)
resource "aws_sns_topic_subscription" "sms_subscription" {
  topic_arn = aws_sns_topic.order_notifications.arn
  protocol  = "sms"
  endpoint  = var.sms_endpoint
  
  # Filter policy: Only send tracking SMS
  filter_policy = jsonencode({
    message_type = ["order_tracking"]
  })
}

# SQS Queue Policy to allow SNS to send messages
resource "aws_sqs_queue_policy" "warehouse_queue_policy" {
  queue_url = aws_sqs_queue.warehouse_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.warehouse_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_notifications.arn
          }
        }
      }
    ]
  })
}

# SNS Subscription: SQS (for warehouse processing)
resource "aws_sns_topic_subscription" "sqs_subscription" {
  topic_arn = aws_sns_topic.order_notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.warehouse_queue.arn
  
  # Filter policy: Only warehouse-related messages
  filter_policy = jsonencode({
    message_type = ["warehouse_processing"]
  })
  
  depends_on = [aws_sqs_queue_policy.warehouse_queue_policy]
}

# SNS Subscription: Lambda (for analytics)
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.order_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.analytics_processor.arn
  
  # Filter policy: Only analytics messages
  filter_policy = jsonencode({
    message_type = ["analytics"]
  })
}

# Lambda permission for SNS to invoke
resource "aws_lambda_permission" "sns_invoke_lambda" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analytics_processor.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.order_notifications.arn
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.analytics_processor.function_name}"
  retention_in_days = 7

  tags = {
    Environment = "Lab"
    Purpose     = "SNS-Education"
  }
}

