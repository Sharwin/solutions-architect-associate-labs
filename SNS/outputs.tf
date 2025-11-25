output "sns_topic_arn" {
  description = "ARN of the SNS Topic"
  value       = aws_sns_topic.order_notifications.arn
}

output "sns_topic_name" {
  description = "Name of the SNS Topic"
  value       = aws_sns_topic.order_notifications.name
}

output "sqs_queue_url" {
  description = "URL of the Warehouse SQS Queue"
  value       = aws_sqs_queue.warehouse_queue.url
}

output "sqs_queue_arn" {
  description = "ARN of the Warehouse SQS Queue"
  value       = aws_sqs_queue.warehouse_queue.arn
}

output "lambda_function_name" {
  description = "Name of the Analytics Lambda Function"
  value       = aws_lambda_function.analytics_processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Analytics Lambda Function"
  value       = aws_lambda_function.analytics_processor.arn
}

