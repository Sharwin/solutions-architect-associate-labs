# Amazon SNS Hands-On Lab Guide

## Lab Overview

This lab demonstrates Amazon Simple Notification Service (SNS) by building an e-commerce order notification system. You will learn how to:

- Create SNS topics and configure multiple subscription types
- Implement message filtering using message attributes
- Integrate SNS with SQS, Lambda, Email, and SMS
- Understand the fanout pattern and pub/sub messaging

**Lab Duration:** 30-45 minutes  
**Difficulty Level:** Intermediate  
**AWS Services Used:** SNS, SQS, Lambda, CloudWatch Logs, CloudFormation

---

## Prerequisites

Before starting, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured (`aws configure`)
3. **Python 3.11+** installed
4. **Valid email address** for testing
5. **Phone number** for SMS testing (optional)

Verify your setup:

```bash
aws --version
python3 --version
aws sts get-caller-identity
```

**Expected Output:**
```
aws-cli/2.x.x Python/3.x.x
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
-rw-r--r--  1 user  staff  6104 Nov 21 10:00 template.yaml
-rw-r--r--  1 user  staff   789 Nov 21 10:00 analytics_processor.py
-rw-r--r--  1 user  staff   567 Nov 21 10:00 test_sns.py
-rw-r--r--  1 user  staff    45 Nov 21 10:00 requirements.txt
```

---

## Step 2: Deploy Infrastructure with CloudFormation

### 2.1 Deploy the Stack

Deploy the CloudFormation stack using the AWS CLI. Replace the email and phone number with your own.

```bash
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name sns-lab-stack \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    EmailEndpoint="your-email@example.com" \
    SmsEndpoint="+1234567890"
```

**Note:** Replace `your-email@example.com` and `+1234567890` with your actual details.

**Expected Output:**
```
Waiting for changeset to be created..
Waiting for stack create/update to complete
Successfully created/updated stack - sns-lab-stack
```

### 2.2 Verify Deployed Resources

Retrieve the stack outputs to get the SNS Topic ARN and SQS Queue URL.

```bash
aws cloudformation describe-stacks \
  --stack-name sns-lab-stack \
  --query 'Stacks[0].Outputs' \
  --output table
```

**Expected Output:**
```
------------------------------------------------------------------------------------------------------------------------
|                                                   DescribeStacks                                                     |
+-------------------+--------------------------------------------------------------------------------------------------+
|  OutputKey        |  OutputValue                                                                                     |
+-------------------+--------------------------------------------------------------------------------------------------+
|  SnsTopicArn      |  arn:aws:sns:us-east-1:123456789012:ecommerce-order-notifications                                |
|  WarehouseQueueUrl|  https://sqs.us-east-1.amazonaws.com/123456789012/warehouse-order-processing                     |
+-------------------+--------------------------------------------------------------------------------------------------+
```

### 2.3 Confirm Email Subscription

**Important:** Check your email inbox for a message from AWS SNS with subject "AWS Notification - Subscription Confirmation". Click the confirmation link to activate the email subscription.

```bash
# Get Topic ARN from stack output
TOPIC_ARN=$(aws cloudformation describe-stacks --stack-name sns-lab-stack --query "Stacks[0].Outputs[?OutputKey=='SnsTopicArn'].OutputValue" --output text)

# List subscriptions to check status
aws sns list-subscriptions-by-topic \
  --topic-arn "$TOPIC_ARN" \
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
TOPIC_ARN=$(aws cloudformation describe-stacks --stack-name sns-lab-stack --query "Stacks[0].Outputs[?OutputKey=='SnsTopicArn'].OutputValue" --output text)

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
QUEUE_URL=$(aws cloudformation describe-stacks --stack-name sns-lab-stack --query "Stacks[0].Outputs[?OutputKey=='WarehouseQueueUrl'].OutputValue" --output text)
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

---

## Step 5: Verify Infrastructure Components

### 5.1 List All SNS Topics

```bash
aws sns list-topics --query 'Topics[*].TopicArn' --output table
```

### 5.2 Get Topic Attributes

```bash
aws sns get-topic-attributes \
  --topic-arn "$TOPIC_ARN" \
  --query '[DisplayName,Owner,SubscriptionsConfirmed]' \
  --output table
```

### 5.3 Check SQS Queue Attributes

```bash
aws sqs get-queue-attributes \
  --queue-url "$QUEUE_URL" \
  --attribute-names All \
  --query 'Attributes.[ApproximateNumberOfMessages,VisibilityTimeout,MessageRetentionPeriod]' \
  --output table
```

### 5.4 Verify Lambda Function

```bash
aws lambda get-function \
  --function-name sns-analytics-processor \
  --query 'Configuration.[FunctionName,Runtime,Handler,LastModified]' \
  --output table
```

---

## Step 6: Understanding Message Filtering

### 6.1 View Filter Policies

```bash
aws sns list-subscriptions-by-topic \
  --topic-arn "$TOPIC_ARN" \
  --query 'Subscriptions[*].[Protocol,FilterPolicy]' \
  --output json
```

### 6.2 Test Filter Matching

Create a test to demonstrate filtering:

```bash
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
aws sqs receive-message --queue-url "$QUEUE_URL"
```

---

## Step 7: Cleanup

### 7.1 Delete CloudFormation Stack

**Warning:** This will delete all resources created in this lab.

```bash
aws cloudformation delete-stack --stack-name sns-lab-stack
```

### 7.2 Verify Deletion

```bash
aws cloudformation describe-stacks --stack-name sns-lab-stack
```

**Expected Output:**
```
An error occurred (ValidationError) when calling the DescribeStacks operation: Stack with id sns-lab-stack does not exist
```

### 7.3 Clean Up Local Files (Optional)

```bash
deactivate  # Exit virtual environment
rm -rf venv
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
  --queue-url "$QUEUE_URL" \
  --attribute-names Policy
```

### Issue: Lambda not being invoked

**Solution:** Check Lambda permissions:
```bash
aws lambda get-policy \
  --function-name sns-analytics-processor
```

### Issue: Messages not matching filters

**Solution:** Verify message attributes match filter policies exactly:
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn "$TOPIC_ARN" \
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
