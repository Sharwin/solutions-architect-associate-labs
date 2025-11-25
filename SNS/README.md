# AWS SNS Hands-On Lab

## 📚 Lab Scenario: E-Commerce Order Notification System

### Real-World Use Case
Imagine you're building an e-commerce platform. When a customer places an order, you need to:
1. **Send Email Confirmation** to the customer
2. **Send SMS Tracking Updates** to the customer's phone
3. **Queue Orders** for warehouse processing via SQS
4. **Process Analytics** data via Lambda function

This lab demonstrates how Amazon SNS can handle all these notification requirements efficiently with message filtering and multiple subscription types.

## 🏗️ Architecture Overview

```
Order Event → SNS Topic (order_notifications)
                    ├── Email Subscription (filter: order_confirmation)
                    ├── SMS Subscription (filter: order_tracking)
                    ├── SQS Subscription (filter: warehouse_processing)
                    └── Lambda Subscription (filter: analytics)
```

## 📋 Prerequisites

- AWS CLI configured with credentials
- Terraform installed
- Python 3.11+ installed
- Valid email address for testing
- Phone number for SMS (optional)

## 🚀 Deployment Steps

### 1. Configure Variables

Edit `terraform.tfvars` or set environment variables:
```bash
export TF_VAR_email_endpoint="your-email@example.com"
export TF_VAR_sms_endpoint="+1234567890"  # E.164 format
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review the Plan
```bash
terraform plan
```

### 4. Deploy Infrastructure
```bash
terraform apply
```

**Important:** When you apply, you'll receive an email confirmation request. **You must confirm the subscription** before messages will be delivered!

### 5. Confirm Email Subscription
Check your email and click the confirmation link in the SNS subscription email.

## 🧪 Testing

### Setup Python Environment
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Run Test Script
```bash
python test_sns.py
```

### Manual Testing with AWS CLI

#### Publish Order Confirmation (Email)
```bash
TOPIC_ARN=$(terraform output -raw sns_topic_arn)

aws sns publish \
  --topic-arn $TOPIC_ARN \
  --subject "Order Confirmation" \
  --message '{"order_id":"ORD-12345","message":"Your order has been confirmed!"}' \
  --message-attributes '{"message_type":{"DataType":"String","StringValue":"order_confirmation"}}'
```

#### Publish Warehouse Processing (SQS)
```bash
aws sns publish \
  --topic-arn $TOPIC_ARN \
  --message '{"order_id":"ORD-12345","message":"Order ready for processing"}' \
  --message-attributes '{"message_type":{"DataType":"String","StringValue":"warehouse_processing"}}'

# Check SQS queue
QUEUE_URL=$(terraform output -raw sqs_queue_url)
aws sqs receive-message --queue-url $QUEUE_URL
```

#### Publish Analytics (Lambda)
```bash
aws sns publish \
  --topic-arn $TOPIC_ARN \
  --message '{"order_id":"ORD-12345","order_value":99.99}' \
  --message-attributes '{"message_type":{"DataType":"String","StringValue":"analytics"}}'

# Check Lambda logs
aws logs tail /aws/lambda/sns-analytics-processor --follow
```

## 📖 AWS SAA-C03 Exam Tips

### Key SNS Concepts

1. **Message Filtering**
   - Filter policies use JSON matching
   - Only matching subscribers receive messages
   - Reduces unnecessary message delivery
   - **Exam Tip:** Filter policies are evaluated per subscription, not per topic

2. **Subscription Types**
   - **Email/Email-JSON**: Requires confirmation (opt-in)
   - **SMS**: Requires phone number in E.164 format (+1234567890)
   - **SQS**: Must grant SNS permission to write to SQS queue
   - **Lambda**: Requires Lambda permission for SNS to invoke
   - **HTTP/HTTPS**: Requires endpoint to confirm subscription

3. **Message Attributes**
   - Up to 10 attributes per message
   - Used for filtering and routing
   - Data types: String, Number, Binary

4. **Dead Letter Queues (DLQ)**
   - Used for failed message deliveries
   - Can be SQS queue or another SNS topic
   - **Exam Tip:** DLQ helps prevent message loss and enables retry logic

5. **Pricing Model**
   - **Free Tier**: 1 million requests/month
   - **Pricing**: $0.50 per 1 million requests
   - SMS pricing varies by country
   - **Exam Tip:** SNS is pay-per-use, no upfront costs

6. **Limits**
   - Topic name: 256 characters max
   - Message size: 256 KB max
   - Message attributes: 10 max
   - **Exam Tip:** For larger payloads, use S3 and send S3 URL via SNS

7. **Fanout Pattern**
   - One message → Multiple subscribers
   - Decouples publishers from subscribers
   - **Exam Tip:** Common pattern for microservices architecture

8. **Message Ordering**
   - SNS does NOT guarantee message ordering
   - For ordered delivery, use SQS FIFO queues
   - **Exam Tip:** If order matters, use SQS FIFO, not SNS directly

9. **Cross-Region Publishing**
   - Can publish across regions
   - Topic ARN includes region
   - **Exam Tip:** Consider latency and compliance requirements

10. **Security**
    - IAM policies control access
    - Can encrypt messages at rest (KMS)
    - VPC endpoints available
    - **Exam Tip:** Use IAM policies to restrict who can publish/subscribe

## 🧹 Cleanup

To avoid charges, destroy all resources:
```bash
terraform destroy
```

## 📚 Additional Resources

- [AWS SNS Documentation](https://docs.aws.amazon.com/sns/)
- [SNS Best Practices](https://docs.aws.amazon.com/sns/latest/dg/sns-best-practices.html)
- [SNS Message Filtering](https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html)

