# AWS SQS Hands-On Lab

## 📚 Lab Scenario: E-commerce Order Processing System

This lab demonstrates a real-world e-commerce scenario where we use **Amazon SQS** to decouple order processing components:

- **Standard Queue**: Handles high-volume order notifications (emails, SMS, etc.)
- **FIFO Queue**: Processes critical payment transactions with strict ordering
- **Dead Letter Queues**: Captures failed messages after retry attempts

## 🏗️ Architecture

```
┌─────────────┐         ┌──────────────────┐         ┌─────────────┐
│   Producer  │────────▶│  Standard Queue  │────────▶│  Consumer   │
│  (Orders)   │         │ (Notifications)  │         │  (Email/SMS)│
└─────────────┘         └──────────────────┘         └─────────────┘
                               │
                               │ (Failed after 3 retries)
                               ▼
                        ┌──────────────┐
                        │     DLQ      │
                        └──────────────┘

┌─────────────┐         ┌──────────────────┐         ┌─────────────┐
│   Producer  │────────▶│   FIFO Queue     │────────▶│  Consumer   │
│ (Payments)  │         │ (Payment Proc.)  │         │  (Payment)  │
└─────────────┘         └──────────────────┘         └─────────────┘
                               │
                               │ (Failed after 3 retries)
                               ▼
                        ┌──────────────┐
                        │   FIFO DLQ   │
                        └──────────────┘
```

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with credentials
- Terraform installed
- Python 3.x with boto3

### Step 1: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy resources
terraform apply
```

### Step 2: Install Python Dependencies

```bash
pip3 install -r requirements.txt
```

### Step 3: Get Queue URLs

After deployment, Terraform will output the queue URLs. Or get them manually:

```bash
# Get Standard Queue URL
aws sqs get-queue-url --queue-name order-notifications-queue

# Get FIFO Queue URL
aws sqs get-queue-url --queue-name payment-processing-queue.fifo
```

### Step 4: Send Messages (Producer)

```bash
python3 producer.py <STANDARD_QUEUE_URL> <FIFO_QUEUE_URL>
```

### Step 5: Receive Messages (Consumer)

```bash
python3 consumer.py <STANDARD_QUEUE_URL> <FIFO_QUEUE_URL> 10
```

## 🧪 Testing with AWS CLI

### Send a message to Standard Queue

```bash
aws sqs send-message \
  --queue-url <STANDARD_QUEUE_URL> \
  --message-body '{"order_id":"ORD-999","total":199.99}'
```

### Send a message to FIFO Queue

```bash
aws sqs send-message \
  --queue-url <FIFO_QUEUE_URL> \
  --message-body '{"payment_id":"PAY-999","amount":199.99}' \
  --message-group-id "payment-group-1" \
  --message-deduplication-id "dedup-999"
```

### Receive messages

```bash
aws sqs receive-message \
  --queue-url <QUEUE_URL> \
  --max-number-of-messages 10 \
  --wait-time-seconds 20
```

### Check queue attributes

```bash
aws sqs get-queue-attributes \
  --queue-url <QUEUE_URL> \
  --attribute-names All
```

## 📖 AWS SAA-C03 Exam Tips

### Standard Queue vs FIFO Queue

| Feature | Standard Queue | FIFO Queue |
|---------|---------------|------------|
| **Throughput** | Unlimited | 3,000 messages/second (with batching: 3,000/second) |
| **Ordering** | Best-effort (not guaranteed) | Strict FIFO ordering |
| **Delivery** | At-least-once (may have duplicates) | Exactly-once processing |
| **Deduplication** | No | Yes (content-based or explicit) |
| **Message Groups** | No | Yes (for parallel processing) |
| **Pricing** | $0.40 per million requests | $0.50 per million requests |
| **Name** | Any name | Must end with `.fifo` |

### Key Limits & Constraints

1. **Message Size**: 
   - Maximum: 256 KB (262,144 bytes)
   - For larger payloads: Use S3 and send S3 reference in message

2. **Message Retention**:
   - Standard: 1 minute to 14 days (default: 4 days)
   - DLQ: Up to 14 days

3. **Visibility Timeout**:
   - Range: 0 to 12 hours (default: 30 seconds)
   - If not deleted within timeout, message becomes visible again

4. **Long Polling**:
   - `WaitTimeSeconds`: 0-20 seconds
   - Reduces empty responses and costs
   - **Best Practice**: Always use long polling (20 seconds)

5. **Short Polling**:
   - `WaitTimeSeconds`: 0 seconds
   - Returns immediately (may be empty)
   - More API calls = higher cost

### Dead Letter Queue (DLQ)

- **Purpose**: Capture messages that fail processing after max retries
- **Configuration**: Set `maxReceiveCount` in redrive policy
- **Retention**: Up to 14 days
- **Best Practice**: Always configure DLQ for production queues

### Visibility Timeout

- **Default**: 30 seconds
- **Rule**: Should be > processing time + network latency
- **If too short**: Message becomes visible again before processing completes → duplicate processing
- **If too long**: Failed messages take longer to retry

### Message Attributes

- **Metadata**: Up to 10 attributes per message
- **Size**: Each attribute name/value pair: 256 bytes
- **Use Cases**: Filtering, routing, metadata without parsing body

### Security & Access

- **IAM Policies**: Control access to queues
- **Server-Side Encryption (SSE)**: Use KMS keys
- **VPC Endpoints**: Access SQS without internet gateway
- **Queue Policies**: Resource-based policies

### Pricing Model

- **Charges**: Based on requests (send, receive, delete)
- **Free Tier**: 1 million requests/month
- **Standard**: $0.40 per million requests
- **FIFO**: $0.50 per million requests
- **Data Transfer**: Outbound charges apply

### Best Practices

1. **Use Long Polling**: Reduces empty responses and costs
2. **Configure DLQ**: Always set up dead letter queues
3. **Set Appropriate Visibility Timeout**: Based on processing time
4. **Batch Operations**: Use `SendMessageBatch` (up to 10 messages)
5. **Idempotency**: Design consumers to handle duplicate messages
6. **Monitor**: Use CloudWatch metrics (ApproximateNumberOfMessages, etc.)

### Integration Patterns

- **SQS + Lambda**: Event-driven processing
- **SQS + SNS**: Fan-out pattern (one message to many queues)
- **SQS + Auto Scaling**: Scale workers based on queue depth
- **SQS + Step Functions**: Workflow orchestration

### Common Exam Scenarios

1. **High Throughput**: Use Standard Queue
2. **Order Matters**: Use FIFO Queue
3. **No Duplicates**: Use FIFO Queue with deduplication
4. **Large Payloads**: Store in S3, send reference in message
5. **Failed Messages**: Configure DLQ with appropriate maxReceiveCount

## 🧹 Cleanup

```bash
# Destroy all resources
terraform destroy
```

## 📊 Monitoring

View queue metrics in CloudWatch:

```bash
# Get approximate number of messages
aws sqs get-queue-attributes \
  --queue-url <QUEUE_URL> \
  --attribute-names ApproximateNumberOfMessages
```

Key CloudWatch Metrics:
- `ApproximateNumberOfMessages`: Messages available for retrieval
- `ApproximateNumberOfMessagesNotVisible`: Messages in flight
- `NumberOfMessagesSent`: Messages sent to queue
- `NumberOfMessagesReceived`: Messages received from queue
- `NumberOfMessagesDeleted`: Messages successfully deleted

## 🎓 Learning Objectives

After completing this lab, you should understand:

1. ✅ Difference between Standard and FIFO queues
2. ✅ How to configure Dead Letter Queues
3. ✅ Long polling vs short polling
4. ✅ Message attributes and metadata
5. ✅ Visibility timeout and message lifecycle
6. ✅ Best practices for SQS in production
7. ✅ Integration patterns with other AWS services

