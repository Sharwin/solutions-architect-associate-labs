# Amazon SNS Hands-On Lab Guide

## Lab Overview

This lab demonstrates Amazon Simple Notification Service (SNS) by building an e-commerce order notification system. You will learn how to:

- Create SNS topics and configure multiple subscription types
- Implement message filtering using message attributes
- Integrate SNS with SQS, Lambda, Email, and SMS
- Understand the fanout pattern and pub/sub messaging

**Lab Duration:** 30-45 minutes  
**Difficulty Level:** Intermediate  
**AWS Services Used:** SNS, SQS, Lambda, CloudWatch Logs

---

## Prerequisites

Before starting, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured (`aws configure`)
3. **Terraform** installed (version >= 1.0)
4. **Python 3.11+** installed
5. **Valid email address** for testing
6. **Phone number** for SMS testing (optional)

Verify your setup:

```bash
aws --version
terraform version
python3 --version
aws sts get-caller-identity
```

**Expected Output:**
```
aws-cli/2.x.x Python/3.x.x
Terraform v1.x.x
Python 3.11.x
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

---

## Lab Architecture

```
┌─────────────────┐
│  Order Event    │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│   SNS Topic                         │
│   (order_notifications)             │
└────────┬────────────────────────────┘
         │
         ├──► Email Subscription (filter: order_confirmation)
         ├──► SMS Subscription (filter: order_tracking)
         ├──► SQS Queue (filter: warehouse_processing)
         └──► Lambda Function (filter: analytics)
```

---

## Step 1: Prepare the Lab Environment

### 1.1 Navigate to Lab Directory

```bash
cd /path/to/SNS
ls -la
```

**Expected Output:**
```
total 48
drwxr-xr-x  8 user  staff   256 Nov 21 10:00 .
drwxr-xr-x  3 user  staff    96 Nov 21 09:00 ..
-rw-r--r--  1 user  staff  1234 Nov 21 10:00 main.tf
-rw-r--r--  1 user  staff   234 Nov 21 10:00 variables.tf
-rw-r--r--  1 user  staff   456 Nov 21 10:00 outputs.tf
-rw-r--r--  1 user  staff   789 Nov 21 10:00 analytics_processor.py
-rw-r--r--  1 user  staff   567 Nov 21 10:00 test_sns.py
-rw-r--r--  1 user  staff    45 Nov 21 10:00 requirements.txt
```

### 1.2 Create Lambda Deployment Package

The Lambda function code needs to be packaged as a ZIP file:

```bash
zip analytics_processor.zip analytics_processor.py
```

**Expected Output:**
```
  adding: analytics_processor.py (deflated 56%)
```

### 1.3 Configure Variables (Optional)

Create `terraform.tfvars` or set environment variables:

```bash
# Option 1: Create terraform.tfvars
cat > terraform.tfvars << EOF
aws_region     = "us-east-1"
email_endpoint = "your-email@example.com"
sms_endpoint   = "+1234567890"
EOF

# Option 2: Set environment variables
export TF_VAR_email_endpoint="your-email@example.com"
export TF_VAR_sms_endpoint="+1234567890"
```

**Note:** Replace with your actual email and phone number (E.164 format: +1234567890).

---

## Step 2: Deploy Infrastructure with Terraform

### 2.1 Initialize Terraform

```bash
terraform init
```

**Expected Output:**
```
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Finding latest version of hashicorp/archive...
- Installing hashicorp/aws v5.100.0...
- Installed hashicorp/aws v5.100.0 (signed by HashiCorp)
- Installing hashicorp/archive v2.7.1...
- Installed hashicorp/archive v2.7.1 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.
```

### 2.2 Review Deployment Plan

```bash
terraform plan
```

**Expected Output (abbreviated):**
```
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Plan: 14 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + lambda_function_arn  = (known after apply)
  + lambda_function_name = "sns-analytics-processor"
  + sns_topic_arn        = (known after apply)
  + sns_topic_name       = "ecommerce-order-notifications"
  + sqs_queue_arn        = (known after apply)
  + sqs_queue_url        = (known after apply)
```

### 2.3 Deploy Infrastructure

```bash
terraform apply -auto-approve
```

**Expected Output:**
```
data.archive_file.lambda_zip: Reading...
data.archive_file.lambda_zip: Read complete after 0s

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Plan: 14 to add, 0 to change, 0 to destroy.

aws_iam_role.lambda_role: Creating...
aws_sqs_queue.warehouse_queue: Creating...
aws_sqs_queue.warehouse_dlq: Creating...
aws_sns_topic.order_notifications: Creating...
aws_iam_role.lambda_role: Creation complete after 1s
aws_sns_topic.order_notifications: Creation complete after 1s
aws_iam_role_policy.lambda_policy: Creating...
aws_lambda_function.analytics_processor: Creating...
aws_sns_topic_subscription.sms_subscription: Creating...
aws_sns_topic_subscription.email_subscription: Creating...
aws_sns_topic_subscription.email_subscription: Creation complete after 1s
aws_sns_topic_subscription.sms_subscription: Creation complete after 1s
aws_iam_role_policy.lambda_policy: Creation complete after 0s
aws_lambda_function.analytics_processor: Creation complete after 15s
aws_lambda_permission.sns_invoke_lambda: Creating...
aws_cloudwatch_log_group.lambda_logs: Creating...
aws_sns_topic_subscription.lambda_subscription: Creating...
aws_lambda_permission.sns_invoke_lambda: Creation complete after 0s
aws_cloudwatch_log_group.lambda_logs: Creation complete after 0s
aws_sns_topic_subscription.lambda_subscription: Creation complete after 1s
aws_sqs_queue.warehouse_queue: Creation complete after 26s
aws_sqs_queue.warehouse_dlq: Creation complete after 26s
aws_sqs_queue_redrive_policy.warehouse_queue: Creating...
aws_sqs_queue_policy.warehouse_queue_policy: Creating...
aws_sqs_queue_redrive_policy.warehouse_queue: Creation complete after 26s
aws_sqs_queue_policy.warehouse_queue_policy: Creation complete after 26s
aws_sns_topic_subscription.sqs_subscription: Creation complete after 1s

Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:sns-analytics-processor"
lambda_function_name = "sns-analytics-processor"
sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:ecommerce-order-notifications"
sns_topic_name = "ecommerce-order-notifications"
sqs_queue_arn = "arn:aws:sqs:us-east-1:123456789012:warehouse-order-processing"
sqs_queue_url = "https://sqs.us-east-1.amazonaws.com/123456789012/warehouse-order-processing"
```

### 2.4 Verify Deployed Resources

```bash
terraform output
```

**Expected Output:**
```
lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:sns-analytics-processor"
lambda_function_name = "sns-analytics-processor"
sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:ecommerce-order-notifications"
sns_topic_name = "ecommerce-order-notifications"
sqs_queue_arn = "arn:aws:sqs:us-east-1:123456789012:warehouse-order-processing"
sqs_queue_url = "https://sqs.us-east-1.amazonaws.com/123456789012/warehouse-order-processing"
```

### 2.5 Confirm Email Subscription

**Important:** Check your email inbox for a message from AWS SNS with subject "AWS Notification - Subscription Confirmation". Click the confirmation link to activate the email subscription.

```bash
# List subscriptions to check status
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --query 'Subscriptions[*].[Protocol,Endpoint,SubscriptionArn]' \
  --output table
```

**Expected Output:**
```
----------------------------------------------------------------------------------------------------------
|                                    ListSubscriptionsByTopic                                             |
+--------+--------------------------------------------------------------------------+-------------------+
|  email |  your-email@example.com                                                  |  PendingConfirmation |
|  sqs   |  arn:aws:sqs:us-east-1:123456789012:warehouse-order-processing           |  arn:aws:sns:...   |
|  sms   |  +1234567890                                                             |  arn:aws:sns:...   |
|  lambda|  arn:aws:lambda:us-east-1:123456789012:function:sns-analytics-processor  |  arn:aws:sns:...   |
+--------+--------------------------------------------------------------------------+-------------------+
```

**Note:** The email subscription will show "PendingConfirmation" until you click the confirmation link in your email.

---

## Step 3: Test SNS Functionality

### 3.1 Set Up Python Environment

```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

**Expected Output:**
```
created virtual environment CPython3.11.x in venv
Activating virtual environment...
Collecting boto3>=1.28.0
  Downloading boto3-1.34.x-py3-none-any.whl
Collecting botocore>=1.31.0
  Downloading botocore-1.34.x-py3-none-any.whl
...
Successfully installed boto3-1.34.x botocore-1.34.x ...
```

### 3.2 Run Automated Test Script

```bash
python test_sns.py
```

**Expected Output:**
```
============================================================
🚀 SNS Lab Testing Script
============================================================

📢 SNS Topic ARN: arn:aws:sns:us-east-1:123456789012:ecommerce-order-notifications


============================================================
TEST 1: Publishing Order Confirmation (Email)
============================================================
✅ Published order_confirmation message - MessageId: d510805e-30bf-5eb5-90d5-e1c7e3f8ffd6

============================================================
TEST 2: Publishing Order Tracking (SMS)
============================================================
✅ Published order_tracking message - MessageId: de93e47a-e005-5e7e-be8f-85e33342cf1d

============================================================
TEST 3: Publishing Warehouse Processing (SQS)
============================================================
✅ Published warehouse_processing message - MessageId: 3ba86170-31fb-5e78-b572-00e9e2bc1f1b

⏳ Waiting 3 seconds for message to arrive in SQS...

📦 Found 1 message(s) in warehouse queue:
   Order ID: ORD-12345
   Message: Order ready for warehouse processing
   ReceiptHandle: AQEB3fdSsYxq/HpfVT6DsCpU9sFS6HvvW7B1oStWhBf2lwcs6V...

✅ Messages processed and deleted from queue

============================================================
TEST 4: Publishing Analytics Data (Lambda)
============================================================
✅ Published analytics message - MessageId: a49e75e1-c663-5254-a392-147815289337

⏳ Waiting 5 seconds for Lambda to process...

📊 Check CloudWatch Logs for Lambda execution:
   Log Group: /aws/lambda/sns-analytics-processor

============================================================
✅ Testing Complete!
============================================================

📧 Check your email for order confirmation
📱 Check your phone for SMS notification (if configured)
📋 Check CloudWatch Logs for Lambda execution
📦 Check SQS queue for warehouse messages
```

---

## Step 4: Manual Testing with AWS CLI

### 4.1 Publish Order Confirmation Message (Email)

```bash
TOPIC_ARN=$(terraform output -raw sns_topic_arn)

aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --subject "Order Confirmation" \
  --message '{"order_id":"ORD-12345","customer_id":"CUST-001","order_value":99.99,"message":"Your order has been confirmed!"}' \
  --message-attributes 'message_type={DataType=String,StringValue=order_confirmation}'
```

**Expected Output:**
```json
{
    "MessageId": "d510805e-30bf-5eb5-90d5-e1c7e3f8ffd6"
}
```

**Verification:** Check your email inbox for the order confirmation message.

### 4.2 Publish Order Tracking Message (SMS)

```bash
aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message '{"order_id":"ORD-12345","tracking_number":"TRACK-98765","status":"Shipped","message":"Your order has been shipped!"}' \
  --message-attributes 'message_type={DataType=String,StringValue=order_tracking}'
```

**Expected Output:**
```json
{
    "MessageId": "de93e47a-e005-5e7e-be8f-85e33342cf1d"
}
```

**Verification:** Check your phone for SMS notification (if SMS endpoint is configured).

### 4.3 Publish Warehouse Processing Message (SQS)

```bash
aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message '{"order_id":"ORD-12345","items":["Item-A","Item-B","Item-C"],"priority":"Normal","message":"Order ready for warehouse processing"}' \
  --message-attributes 'message_type={DataType=String,StringValue=warehouse_processing}'

# Wait a few seconds for message to arrive
sleep 3

# Check SQS queue
QUEUE_URL=$(terraform output -raw sqs_queue_url)
aws sqs receive-message --queue-url "$QUEUE_URL" --max-number-of-messages 1
```

**Expected Output:**
```json
{
    "Messages": [
        {
            "MessageId": "277d72ec-9890-4cbe-88d4-56a88c74c3c3",
            "ReceiptHandle": "AQEBXuekh5OdsFOOm8BUX5nb84inRFHk2CXJ6CEXi5yWa7IL8ID4IJtVcC3J3BaDcJYh3mjuwE+tmpXjw9nrcwtJ9AvfP0k070XzKKjX7QkJmKsdh2WpqQtnaCJMlweDvn1L3E9OlhcU7dtxtwcc3NVlECox0srSFlK4EjfsS/bYu/DtvCzeayUUvJTDEOEkSZ4m/zXGB+YSn9Q26OcluMSUEhuTMsMFcSfw1GgbabtMuMK1BVpwOu+/gyY195WWPQi44zYzb2Vvv+LNv0tQPHgU9IUumGhtQFBWMdSGuWmMR4l99+VSLlsCoiqDD6HMwwG5NfQtjj1Fu0jtCEyhR9F1yFhEoaUFvlON895QdOsC4vfFokD6TgHu/kN9OZzoBU6rzd9FWoKRV1u8Tac5zIFNvQ==",
            "MD5OfBody": "4728a8993d5dcf23ec632ba421be8481",
            "Body": "{\n  \"Type\" : \"Notification\",\n  \"MessageId\" : \"3ba86170-31fb-5e78-b572-00e9e2bc1f1b\",\n  \"TopicArn\" : \"arn:aws:sns:us-east-1:123456789012:ecommerce-order-notifications\",\n  \"Message\" : \"{\\\"order_id\\\":\\\"ORD-12345\\\",\\\"items\\\":[\\\"Item-A\\\",\\\"Item-B\\\",\\\"Item-C\\\"],\\\"priority\\\":\\\"Normal\\\",\\\"message\\\":\\\"Order ready for warehouse processing\\\"}\",\n  \"Timestamp\" : \"2024-11-21T02:35:23.741Z\",\n  \"SignatureVersion\" : \"1\",\n  \"MessageAttributes\" : {\n    \"message_type\" : {\"Type\":\"String\",\"Value\":\"warehouse_processing\"}\n  }\n}"
        }
    ]
}
```

**Key Observations:**
- The message body is wrapped in SNS notification format
- The original message is in the `Message` field
- Message attributes are preserved
- The message matches the filter policy (`warehouse_processing`)

### 4.4 Publish Analytics Message (Lambda)

```bash
aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message '{"order_id":"ORD-12345","customer_id":"CUST-001","order_value":99.99,"timestamp":"2024-01-15T10:30:00Z","message":"Analytics data for processing"}' \
  --message-attributes 'message_type={DataType=String,StringValue=analytics}'

# Wait for Lambda to process
sleep 5

# Check Lambda logs
aws logs tail /aws/lambda/sns-analytics-processor --since 2m --format short
```

**Expected Output:**
```
2024-11-21T02:40:15.123Z  START RequestId: abc123-def456-ghi789
2024-11-21T02:40:15.234Z  INFO Received event: {"Records":[...]}
2024-11-21T02:40:15.345Z  INFO Processing analytics message: {'order_id': 'ORD-12345', 'customer_id': 'CUST-001', 'order_value': 99.99}
2024-11-21T02:40:15.456Z  INFO Analytics processed - Order ID: ORD-12345, Customer: CUST-001, Value: $99.99
2024-11-21T02:40:15.567Z  END RequestId: abc123-def456-ghi789
```

**Verification:** The Lambda function successfully processed the analytics message and logged the details.

### 4.5 Verify Message Filtering

Test that messages are correctly filtered by publishing a message that doesn't match any filter:

```bash
# Publish message with no matching filter
aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message '{"order_id":"ORD-99999","message":"This should not be delivered"}' \
  --message-attributes 'message_type={DataType=String,StringValue=unknown_type}'

# Check SQS queue (should be empty)
aws sqs receive-message --queue-url "$QUEUE_URL" --wait-time-seconds 2
```

**Expected Output:**
```json
{
    "Messages": []
}
```

**Explanation:** The message with `message_type=unknown_type` doesn't match any filter policy, so no subscribers receive it. This demonstrates how message filtering works in SNS.

---

## Step 5: Verify Infrastructure Components

### 5.1 List All SNS Topics

```bash
aws sns list-topics --query 'Topics[*].TopicArn' --output table
```

**Expected Output:**
```
----------------------------------------------------------
|                      ListTopics                        |
+--------------------------------------------------------+
|  arn:aws:sns:us-east-1:123456789012:ecommerce-order-notifications |
+--------------------------------------------------------+
```

### 5.2 Get Topic Attributes

```bash
aws sns get-topic-attributes \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --query '[DisplayName,Owner,SubscriptionsConfirmed]' \
  --output table
```

**Expected Output:**
```
----------------------------------------
|         GetTopicAttributes           |
+--------------------------------------+
|  E-Commerce Order Notifications      |
|  123456789012                        |
|  3                                   |
+--------------------------------------+
```

### 5.3 Check SQS Queue Attributes

```bash
QUEUE_URL=$(terraform output -raw sqs_queue_url)
aws sqs get-queue-attributes \
  --queue-url "$QUEUE_URL" \
  --attribute-names All \
  --query 'Attributes.[ApproximateNumberOfMessages,VisibilityTimeout,MessageRetentionPeriod]' \
  --output table
```

**Expected Output:**
```
----------------------------------------
|      GetQueueAttributes              |
+--------------------------------------+
|  0                                   |
|  30                                  |
|  345600                              |
+--------------------------------------+
```

### 5.4 Verify Lambda Function

```bash
aws lambda get-function \
  --function-name $(terraform output -raw lambda_function_name) \
  --query 'Configuration.[FunctionName,Runtime,Handler,LastModified]' \
  --output table
```

**Expected Output:**
```
----------------------------------------------------------------------------------------------------------
|                                    GetFunction                                                          |
+------------------+------------+---------------------------+------------------------------------------+
|  sns-analytics-processor |  python3.11 |  analytics_processor.lambda_handler |  2024-11-21T02:20:15.000+0000 |
+------------------+------------+---------------------------+------------------------------------------+
```

---

## Step 6: Understanding Message Filtering

### 6.1 View Filter Policies

```bash
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --query 'Subscriptions[*].[Protocol,FilterPolicy]' \
  --output json
```

**Expected Output:**
```json
[
    [
        "email",
        "{\"message_type\":[\"order_confirmation\"]}"
    ],
    [
        "sqs",
        "{\"message_type\":[\"warehouse_processing\"]}"
    ],
    [
        "sms",
        "{\"message_type\":[\"order_tracking\"]}"
    ],
    [
        "lambda",
        "{\"message_type\":[\"analytics\"]}"
    ]
]
```

**Key Concept:** Each subscription has its own filter policy. Messages are evaluated against each subscription's filter independently.

### 6.2 Test Filter Matching

Create a test to demonstrate filtering:

```bash
TOPIC_ARN=$(terraform output -raw sns_topic_arn)

# Test 1: Message matches email filter
echo "Test 1: Publishing order_confirmation (should go to email)"
aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message '{"test":"email"}' \
  --message-attributes 'message_type={DataType=String,StringValue=order_confirmation}'

# Test 2: Message matches SQS filter
echo "Test 2: Publishing warehouse_processing (should go to SQS)"
aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message '{"test":"sqs"}' \
  --message-attributes 'message_type={DataType=String,StringValue=warehouse_processing}'

sleep 3
aws sqs receive-message --queue-url $(terraform output -raw sqs_queue_url)
```

---

## Step 7: Cleanup

### 7.1 Destroy All Resources

**Warning:** This will delete all resources created in this lab.

```bash
terraform destroy -auto-approve
```

**Expected Output:**
```
aws_sns_topic_subscription.sqs_subscription: Refreshing state...
aws_sns_topic_subscription.lambda_subscription: Refreshing state...
aws_sns_topic_subscription.email_subscription: Refreshing state...
aws_sns_topic_subscription.sms_subscription: Refreshing state...
...

Plan: 0 to add, 0 to change, 14 to destroy.

aws_sns_topic_subscription.sqs_subscription: Destroying...
aws_sns_topic_subscription.lambda_subscription: Destroying...
aws_sns_topic_subscription.email_subscription: Destroying...
aws_sns_topic_subscription.sms_subscription: Destroying...
aws_lambda_permission.sns_invoke_lambda: Destroying...
aws_sqs_queue_policy.warehouse_queue_policy: Destroying...
aws_sqs_queue_redrive_policy.warehouse_queue: Destroying...
aws_sqs_queue.warehouse_queue: Destroying...
aws_sqs_queue.warehouse_dlq: Destroying...
aws_lambda_function.analytics_processor: Destroying...
aws_cloudwatch_log_group.lambda_logs: Destroying...
aws_iam_role_policy.lambda_policy: Destroying...
aws_iam_role.lambda_role: Destroying...
aws_sns_topic.order_notifications: Destroying...

Destroy complete! Resources: 14 destroyed.
```

### 7.2 Clean Up Local Files (Optional)

```bash
deactivate  # Exit virtual environment
rm -rf venv
rm -f analytics_processor.zip
rm -f terraform.tfstate terraform.tfstate.backup
rm -rf .terraform
```

---

## Key Learnings Summary

### Concepts Demonstrated

1. **SNS Topics**: Central messaging endpoints for pub/sub communication
2. **Multiple Subscription Types**: Email, SMS, SQS, and Lambda integrations
3. **Message Filtering**: Filter policies route messages to specific subscribers
4. **Fanout Pattern**: One message delivered to multiple subscribers
5. **Integration Patterns**: SNS → SQS, SNS → Lambda, SNS → Email/SMS

### Important Takeaways

- **Message Filtering**: Applied per subscription, not per topic
- **Email Subscriptions**: Require confirmation (opt-in model)
- **SQS Integration**: Requires queue policy allowing SNS to send messages
- **Lambda Integration**: Requires Lambda permission for SNS to invoke
- **Message Attributes**: Used for filtering and routing (max 10 per message)
- **Message Size**: Maximum 256 KB per message

### Common Exam Scenarios

1. **Fanout Pattern**: Use SNS when one event needs to trigger multiple systems
2. **Message Filtering**: Use message attributes and filter policies to route messages
3. **Ordering**: SNS doesn't guarantee order; use SQS FIFO if ordering is required
4. **Large Payloads**: Store in S3, send S3 URL via SNS (256 KB limit)

---

## Troubleshooting

### Issue: Email subscription not receiving messages

**Solution:** Check email inbox and confirm the subscription by clicking the confirmation link.

### Issue: SQS queue not receiving messages

**Solution:** Verify the queue policy allows SNS to send messages:
```bash
aws sqs get-queue-attributes \
  --queue-url $(terraform output -raw sqs_queue_url) \
  --attribute-names Policy
```

### Issue: Lambda not being invoked

**Solution:** Check Lambda permissions:
```bash
aws lambda get-policy \
  --function-name $(terraform output -raw lambda_function_name)
```

### Issue: Messages not matching filters

**Solution:** Verify message attributes match filter policies exactly:
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --query 'Subscriptions[*].[Protocol,FilterPolicy]'
```

---

## Additional Resources

- [AWS SNS Documentation](https://docs.aws.amazon.com/sns/)
- [SNS Best Practices](https://docs.aws.amazon.com/sns/latest/dg/sns-best-practices.html)
- [SNS Message Filtering](https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html)
- [SNS Pricing](https://aws.amazon.com/sns/pricing/)

---

## Lab Completion Checklist

- [ ] Infrastructure deployed successfully
- [ ] Email subscription confirmed
- [ ] Tested email notification
- [ ] Tested SMS notification (if configured)
- [ ] Verified SQS message delivery
- [ ] Verified Lambda function execution
- [ ] Tested message filtering
- [ ] Reviewed CloudWatch logs
- [ ] Cleaned up resources

**Congratulations!** You have successfully completed the Amazon SNS hands-on lab.

