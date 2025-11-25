variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "email_endpoint" {
  description = "Email address for SNS email subscription"
  type        = string
  default     = "your-email@example.com"
}

variable "sms_endpoint" {
  description = "Phone number for SNS SMS subscription (E.164 format: +1234567890)"
  type        = string
  default     = "+1234567890"
}

