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

# Standard SQS Queue - For order notifications
# Best for: High throughput, best-effort ordering, at-least-once delivery
resource "aws_sqs_queue" "order_notifications" {
  name                      = "order-notifications-queue"
  delay_seconds            = 0
  max_message_size         = 262144  # 256 KB
  message_retention_seconds = 345600  # 4 days
  receive_wait_time_seconds = 20     # Long polling
  
  # Dead Letter Queue configuration
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_notifications_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = "lab"
    Purpose     = "order-notifications"
  }
}

# Dead Letter Queue for Standard Queue
resource "aws_sqs_queue" "order_notifications_dlq" {
  name                      = "order-notifications-dlq"
  message_retention_seconds = 1209600  # 14 days (max for DLQ)
  
  tags = {
    Environment = "lab"
    Purpose     = "dlq"
  }
}

# FIFO SQS Queue - For payment processing
# Best for: Exactly-once processing, strict ordering, deduplication
resource "aws_sqs_queue" "payment_processing" {
  name                        = "payment-processing-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true  # Automatically deduplicate based on message body
  delay_seconds               = 0
  max_message_size            = 262144  # 256 KB
  message_retention_seconds    = 345600  # 4 days
  receive_wait_time_seconds   = 20      # Long polling
  
  # Dead Letter Queue configuration
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.payment_processing_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = "lab"
    Purpose     = "payment-processing"
  }
}

# Dead Letter Queue for FIFO Queue
resource "aws_sqs_queue" "payment_processing_dlq" {
  name                        = "payment-processing-dlq.fifo"
  fifo_queue                  = true
  message_retention_seconds   = 1209600  # 14 days (max for DLQ)
  content_based_deduplication = true
  
  tags = {
    Environment = "lab"
    Purpose     = "dlq"
  }
}

# Outputs for easy access
output "order_notifications_queue_url" {
  description = "URL of the Standard Order Notifications Queue"
  value       = aws_sqs_queue.order_notifications.url
}

output "order_notifications_queue_arn" {
  description = "ARN of the Standard Order Notifications Queue"
  value       = aws_sqs_queue.order_notifications.arn
}

output "payment_processing_queue_url" {
  description = "URL of the FIFO Payment Processing Queue"
  value       = aws_sqs_queue.payment_processing.url
}

output "payment_processing_queue_arn" {
  description = "ARN of the FIFO Payment Processing Queue"
  value       = aws_sqs_queue.payment_processing.arn
}

output "order_notifications_dlq_url" {
  description = "URL of the Order Notifications DLQ"
  value       = aws_sqs_queue.order_notifications_dlq.url
}

output "payment_processing_dlq_url" {
  description = "URL of the Payment Processing DLQ"
  value       = aws_sqs_queue.payment_processing_dlq.url
}

