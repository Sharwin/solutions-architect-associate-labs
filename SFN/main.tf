provider "aws" {
  region = "us-east-1"
}

# --- IAM Role for Lambdas ---
resource "aws_iam_role" "lambda_role" {
  name = "sfn_lab_lambda_role"

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
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# --- Lambda Functions ---
data "archive_file" "validate_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/validate.py"
  output_path = "${path.module}/lambda/validate.zip"
}

resource "aws_lambda_function" "validate" {
  filename      = data.archive_file.validate_zip.output_path
  function_name = "sfn-lab-validate"
  role          = aws_iam_role.lambda_role.arn
  handler       = "validate.lambda_handler"
  runtime       = "python3.9"
  source_code_hash = data.archive_file.validate_zip.output_base64sha256
}

data "archive_file" "inventory_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/inventory.py"
  output_path = "${path.module}/lambda/inventory.zip"
}

resource "aws_lambda_function" "inventory" {
  filename      = data.archive_file.inventory_zip.output_path
  function_name = "sfn-lab-inventory"
  role          = aws_iam_role.lambda_role.arn
  handler       = "inventory.lambda_handler"
  runtime       = "python3.9"
  source_code_hash = data.archive_file.inventory_zip.output_base64sha256
}

data "archive_file" "payment_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/payment.py"
  output_path = "${path.module}/lambda/payment.zip"
}

resource "aws_lambda_function" "payment" {
  filename      = data.archive_file.payment_zip.output_path
  function_name = "sfn-lab-payment"
  role          = aws_iam_role.lambda_role.arn
  handler       = "payment.lambda_handler"
  runtime       = "python3.9"
  source_code_hash = data.archive_file.payment_zip.output_base64sha256
}

# --- IAM Role for Step Functions ---
resource "aws_iam_role" "sfn_role" {
  name = "sfn_lab_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "sfn_policy" {
  name = "sfn_lab_policy"
  role = aws_iam_role.sfn_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.validate.arn,
          aws_lambda_function.inventory.arn,
          aws_lambda_function.payment.arn
        ]
      }
    ]
  })
}

# --- Step Function State Machine ---
resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "OrderProcessingWorkflow"
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode({
    Comment = "A simple AWS Step Functions state machine that orchestrates an order processing workflow."
    StartAt = "ValidateOrder"
    States = {
      ValidateOrder = {
        Type = "Task"
        Resource = aws_lambda_function.validate.arn
        Next = "CheckInventory"
        Retry = [
            {
                ErrorEquals = ["States.TaskFailed"]
                IntervalSeconds = 2
                MaxAttempts = 2
                BackoffRate = 2.0
            }
        ]
        Catch = [
            {
                ErrorEquals = ["OrderValidationError"]
                Next = "OrderFailed"
            }
        ]
      }
      CheckInventory = {
        Type = "Task"
        Resource = aws_lambda_function.inventory.arn
        Next = "ProcessPayment"
      }
      ProcessPayment = {
        Type = "Task"
        Resource = aws_lambda_function.payment.arn
        Next = "OrderSucceeded"
      }
      OrderSucceeded = {
        Type = "Succeed"
      }
      OrderFailed = {
        Type = "Fail"
        Cause = "Order validation failed."
        Error = "ValidationError"
      }
    }
  })
}
