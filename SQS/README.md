# Amazon SQS Hands-On Lab Guide

## Lab Overview

This lab demonstrates Amazon Simple Queue Service (SQS) by building a real-world e-commerce order processing system. You'll learn the differences between Standard and FIFO queues, configure Dead Letter Queues, and practice sending/receiving messages using both AWS CLI and Python scripts.

**Learning Objectives:**
- Understand Standard vs FIFO queue characteristics
- Configure and use Dead Letter Queues (DLQ)
- Implement long polling for cost optimization
- Send and receive messages using AWS CLI and Python
- Monitor queue metrics and attributes

---

## Prerequisites

Before starting, ensure you have:

- ✅ AWS CLI configured with valid credentials
- ✅ Python 3.x installed
- ✅ Appropriate AWS IAM permissions for SQS and CloudFormation operations

**Verify Prerequisites:**
```bash
# Check AWS CLI
aws --version

# Check Python
python3 --version

# Verify AWS credentials
aws sts get-caller-identity
```

**Expected Output:**
```
aws-cli/2.x.x Python/3.x.x
Python 3.x.x
{
    "UserId": "...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

---

## Step 1: Review the Lab Structure

Navigate to the lab directory and examine the files:

```bash
cd /path/to/SQS
ls -la
```

**Expected Files:**
```
template.yaml        # CloudFormation infrastructure code
producer.py          # Python script to send messages
consumer.py          # Python script to receive messages
requirements.txt     # Python dependencies
README.md            # General documentation
EXAM_TIPS.md         # Exam preparation guide
```

---

## Step 2: Validate CloudFormation Template

Validate the CloudFormation template to ensure it's syntactically correct:

```bash
aws cloudformation validate-template --template-body file://template.yaml
```

**Expected Output:**
```json
{
    "Parameters": [],
    "Description": "SQS Lab Infrastructure",
    "Capabilities": [],
    "CapabilitiesReason": "..."
}
```

---

## Step 3: Review the Infrastructure

The `template.yaml` file defines the following resources:

1. **Standard Queue**: `order-notifications-queue` - High throughput notifications
2. **Standard DLQ**: `order-notifications-dlq` - Captures failed messages
3. **FIFO Queue**: `payment-processing-queue.fifo` - Ordered payment processing
4. **FIFO DLQ**: `payment-processing-dlq.fifo` - Captures failed FIFO messages

---

## Step 4: Deploy the Infrastructure

Deploy the CloudFormation stack:

```bash
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name sqs-lab-stack
```

**Expected Output:**
```
Waiting for changeset to be created..
Waiting for stack create/update to complete
Successfully created/updated stack - sqs-lab-stack
```

**Save the Queue URLs** - You'll need these for testing. Export them as environment variables:

```bash
export STANDARD_QUEUE_URL=$(aws cloudformation describe-stacks --stack-name sqs-lab-stack --query "Stacks[0].Outputs[?OutputKey=='OrderNotificationsQueueUrl'].OutputValue" --output text)
export FIFO_QUEUE_URL=$(aws cloudformation describe-stacks --stack-name sqs-lab-stack --query "Stacks[0].Outputs[?OutputKey=='PaymentProcessingQueueUrl'].OutputValue" --output text)
echo "Standard Queue: $STANDARD_QUEUE_URL"
echo "FIFO Queue: $FIFO_QUEUE_URL"
```

---

## Step 5: Verify Queue Configuration

Check the queue attributes to understand their configuration:

```bash
aws sqs get-queue-attributes \
  --queue-url $STANDARD_QUEUE_URL \
  --attribute-names All \
  --query 'Attributes.{VisibilityTimeout:VisibilityTimeout,MessageRetentionPeriod:MessageRetentionPeriod,ReceiveMessageWaitTimeSeconds:ReceiveMessageWaitTimeSeconds,RedrivePolicy:RedrivePolicy}' \
  --output table
```

**Expected Output:**
```
-----------------------------------------------------------------------------------------------------------------------------------------------
|                                                             GetQueueAttributes                                                              |
+-------------------------------+-------------------------------------------------------------------------------------------------------------+
|  MessageRetentionPeriod       |  345600                                                                                                     |
|  QueueName                    |  None                                                                                                       |
|  ReceiveMessageWaitTimeSeconds|  20                                                                                                         |
|  RedrivePolicy                |  {"deadLetterTargetArn":"arn:aws:sqs:us-east-1:ACCOUNT:order-notifications-dlq","maxReceiveCount":3}   |
|  VisibilityTimeout            |  30                                                                                                         |
+-------------------------------+-------------------------------------------------------------------------------------------------------------+
```

**Key Observations:**
- **ReceiveMessageWaitTimeSeconds: 20** - Long polling enabled (reduces costs)
- **VisibilityTimeout: 30** - Messages hidden for 30 seconds after receipt
- **RedrivePolicy** - DLQ configured with `maxReceiveCount: 3`
- **MessageRetentionPeriod: 345600** - Messages retained for 4 days

---

## Step 6: Install Python Dependencies

Set up a Python virtual environment and install boto3:

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

**Expected Output:**
```
Collecting boto3>=1.28.0
  Downloading boto3-1.34.0-py3-none-any.whl (140 kB)
Successfully installed boto3-1.34.0 botocore-1.34.0 ...
```

**Note:** Always activate the virtual environment before running Python scripts:
```bash
source venv/bin/activate
```

---

## Step 7: Send Messages Using AWS CLI

### 7.1 Send to Standard Queue

Send a test message to the Standard queue:

```bash
aws sqs send-message \
  --queue-url $STANDARD_QUEUE_URL \
  --message-body '{"order_id":"CLI-TEST-001","customer_email":"test@example.com","order_total":49.99,"timestamp":"2024-01-15T10:00:00Z"}' \
  --message-attributes 'OrderType={StringValue=test,DataType=String}' \
  --output json
```

**Expected Output:**
```json
{
    "MD5OfMessageBody": "a3fa5937743645f47ea0ed8865f30bd1",
    "MD5OfMessageAttributes": "27dcf5a0a01a5a1abc64e3ee5c086475",
    "MessageId": "54d8ea9e-1a8e-47db-86ad-f41fbc26d07f"
}
```

**Key Points:**
- Standard queue returns only `MessageId`
- No sequence number (ordering not guaranteed)
- Message attributes included for metadata

### 7.2 Send to FIFO Queue

Send a test message to the FIFO queue:

```bash
aws sqs send-message \
  --queue-url $FIFO_QUEUE_URL \
  --message-body '{"payment_id":"PAY-CLI-001","order_id":"ORD-CLI-001","amount":99.99}' \
  --message-group-id "payment-group-1" \
  --message-deduplication-id "dedup-cli-001" \
  --output json
```

**Expected Output:**
```json
{
    "MD5OfMessageBody": "3e82b314da6e5fc2af66d40c332b66af",
    "MessageId": "cdef6fda-f032-40f9-9343-2461fe068e65",
    "SequenceNumber": "18898244916664047872"
}
```

**Key Differences:**
- FIFO queue returns `SequenceNumber` (proves ordering)
- Requires `MessageGroupId` (groups messages for ordering)
- `MessageDeduplicationId` prevents duplicates (or use content-based deduplication)

---

## Step 8: Check Queue Depth

Verify messages are in the queues:

```bash
echo "Standard Queue Messages:"
aws sqs get-queue-attributes \
  --queue-url $STANDARD_QUEUE_URL \
  --attribute-names ApproximateNumberOfMessages \
  --query 'Attributes.ApproximateNumberOfMessages' \
  --output text

echo "FIFO Queue Messages:"
aws sqs get-queue-attributes \
  --queue-url $FIFO_QUEUE_URL \
  --attribute-names ApproximateNumberOfMessages \
  --query 'Attributes.ApproximateNumberOfMessages' \
  --output text
```

**Expected Output:**
```
Standard Queue Messages:
1
FIFO Queue Messages:
1
```

---

## Step 9: Receive Messages Using AWS CLI

### 9.1 Receive from Standard Queue

Receive messages with long polling:

```bash
aws sqs receive-message \
  --queue-url $STANDARD_QUEUE_URL \
  --max-number-of-messages 1 \
  --wait-time-seconds 5 \
  --output json | python3 -m json.tool
```

**Expected Output:**
```json
{
    "Messages": [
        {
            "MessageId": "54d8ea9e-1a8e-47db-86ad-f41fbc26d07f",
            "ReceiptHandle": "AQEBUVkBKEER+rhNEVtvYsZC3wZQ0WqviCTx5vrd5Eo9H6ML2x...",
            "MD5OfBody": "a3fa5937743645f47ea0ed8865f30bd1",
            "Body": "{\"order_id\":\"CLI-TEST-001\",\"customer_email\":\"test@example.com\",\"order_total\":49.99,\"timestamp\":\"2024-01-15T10:00:00Z\"}"
        }
    ]
}
```

**Important:** After receiving, you must delete the message within the visibility timeout (30 seconds) or it will become visible again.

### 9.2 Delete a Message

Extract the ReceiptHandle and delete the message:

```bash
# Get ReceiptHandle (replace with actual value from previous command)
RECEIPT_HANDLE="AQEBUVkBKEER+rhNEVtvYsZC3wZQ0WqviCTx5vrd5Eo9H6ML2x..."

aws sqs delete-message \
  --queue-url $STANDARD_QUEUE_URL \
  --receipt-handle "$RECEIPT_HANDLE"
```

**Expected Output:** (No output means success)

---

## Step 10: Send Messages Using Python Producer

Use the Python script to send multiple messages:

```bash
source venv/bin/activate
python3 producer.py $STANDARD_QUEUE_URL $FIFO_QUEUE_URL
```

**Expected Output:**
```
============================================================
🚀 SQS Producer - Sending Messages
============================================================

📦 Sending to Standard Queue (Order Notifications)...
✅ Standard Queue: Message sent! MessageId: 7c81844d-a090-45c8-9731-f249067fa4ce
✅ Standard Queue: Message sent! MessageId: b34c4922-cb5f-4d4a-afeb-ff63459f9a86
✅ Standard Queue: Message sent! MessageId: d8f26ded-f6b0-43f4-9e77-2a446115488a

💳 Sending to FIFO Queue (Payment Processing)...
✅ FIFO Queue: Message sent! MessageId: a5aca8aa-dbe6-4fc8-b190-c4c4db0c2070
✅ FIFO Queue: Message sent! MessageId: da6001a1-0e5b-4387-afa6-2816f2f2dc58
✅ FIFO Queue: Message sent! MessageId: 98c2dd07-004a-4c2c-b586-5598d3181749

============================================================
✅ All messages sent successfully!
============================================================
```

**What Happened:**
- Sent 3 messages to Standard queue (order notifications)
- Sent 3 messages to FIFO queue (payment processing)
- Each message includes order details and metadata

---

## Step 11: Receive Messages Using Python Consumer

Process messages using the consumer script:

```bash
source venv/bin/activate
python3 consumer.py $STANDARD_QUEUE_URL $FIFO_QUEUE_URL 10
```

**Expected Output:**
```
============================================================
📥 SQS Consumer - Processing Messages
============================================================

============================================================
📬 Consuming from: Standard Queue (Order Notifications)
============================================================

📨 Processing message from Standard Queue (Order Notifications):
   Message ID: 7c81844d-a090-45c8-9731-f249067fa4ce
   Receipt Handle: AQEBi4NKEmpXdge+YxfUspkaUsw7HXmbj+WIHst/JX/BGtDFDX...
   Body: {
  "order_id": "ORD-001",
  "customer_email": "customer1@example.com",
  "order_total": 99.99,
  "timestamp": "2025-11-20T16:46:36.234023",
  "type": "order_notification"
}
   Attributes: {'OrderTotal': {'StringValue': '99.99', 'DataType': 'Number'}, 'OrderType': {'StringValue': 'standard', 'DataType': 'String'}}
   ✅ Message processed successfully!
   🗑️  Message deleted from queue

... (more messages processed)

✅ Processed 4 messages from Standard Queue (Order Notifications)

============================================================
📬 Consuming from: FIFO Queue (Payment Processing)
============================================================

📨 Processing message from FIFO Queue (Payment Processing):
   Message ID: a5aca8aa-dbe6-4fc8-b190-c4c4db0c2070
   Receipt Handle: AQEBU7j/5rOIPApLLChrMYMwGrtmfcemIpdIKw0sj9cf1MeBAN...
   Body: {
  "order_id": "ORD-001",
  "payment_id": "PAY-001",
  "customer_email": "customer1@example.com",
  "order_total": 99.99,
  "timestamp": "2025-11-20T16:46:38.344650",
  "type": "payment_processing"
}
   Attributes: {'Amount': {'StringValue': '99.99', 'DataType': 'Number'}, 'PaymentType': {'StringValue': 'credit_card', 'DataType': 'String'}}
   ✅ Message processed successfully!
   🗑️  Message deleted from queue

... (more messages processed)

✅ Processed 4 messages from FIFO Queue (Payment Processing)

============================================================
✅ Consumer finished!
============================================================
```

**Key Observations:**
- Messages processed in order (FIFO maintains strict ordering)
- Each message includes attributes (metadata)
- Messages automatically deleted after successful processing
- Long polling waits up to 20 seconds for messages

---

## Step 12: Verify Queues Are Empty

Confirm all messages were processed:

```bash
echo "=== Final Queue Status ==="
echo "Standard Queue Messages:"
aws sqs get-queue-attributes \
  --queue-url $STANDARD_QUEUE_URL \
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
  --query 'Attributes' \
  --output table

echo -e "\nFIFO Queue Messages:"
aws sqs get-queue-attributes \
  --queue-url $FIFO_QUEUE_URL \
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
  --query 'Attributes' \
  --output table
```

**Expected Output:**
```
=== Final Queue Status ===
Standard Queue Messages:
--------------------------------------------------------------------------
|                           GetQueueAttributes                           |
+------------------------------+-----------------------------------------+
|  ApproximateNumberOfMessages |  ApproximateNumberOfMessagesNotVisible  |
+------------------------------+-----------------------------------------+
|  0                           |  0                                      |
+------------------------------+-----------------------------------------+

FIFO Queue Messages:
--------------------------------------------------------------------------
|                           GetQueueAttributes                           |
+------------------------------+-----------------------------------------+
|  ApproximateNumberOfMessages |  ApproximateNumberOfMessagesNotVisible  |
+------------------------------+-----------------------------------------+
|  0                           |  0                                      |
+------------------------------+-----------------------------------------+
```

**Metrics Explained:**
- **ApproximateNumberOfMessages**: Messages available for retrieval
- **ApproximateNumberOfMessagesNotVisible**: Messages currently being processed (in flight)

---

## Step 13: Verify Dead Letter Queue Configuration

Inspect the DLQ redrive policy:

```bash
aws sqs get-queue-attributes \
  --queue-url $STANDARD_QUEUE_URL \
  --attribute-names RedrivePolicy \
  --query 'Attributes.RedrivePolicy' \
  --output text | python3 -m json.tool
```

**Expected Output:**
```json
{
    "deadLetterTargetArn": "arn:aws:sqs:us-east-1:ACCOUNT:order-notifications-dlq",
    "maxReceiveCount": 3
}
```

**What This Means:**
- Messages that fail processing after 3 attempts will be moved to the DLQ
- DLQ retains messages for up to 14 days for investigation

---

## Step 14: Test FIFO Queue Ordering

Demonstrate FIFO ordering by sending multiple messages with the same MessageGroupId:

```bash
# Send 5 messages with same MessageGroupId
for i in {1..5}; do
  aws sqs send-message \
    --queue-url $FIFO_QUEUE_URL \
    --message-body "{\"sequence\":$i,\"message\":\"Message $i\"}" \
    --message-group-id "test-group" \
    --message-deduplication-id "dedup-$i"
  echo "Sent message $i"
done
```

**Expected Output:**
```
Sent message 1
{
    "MessageId": "...",
    "SequenceNumber": "18898244916664047873"
}
Sent message 2
{
    "MessageId": "...",
    "SequenceNumber": "18898244916664047874"
}
... (continues)
```

**Receive and verify ordering:**

```bash
# Receive messages and check sequence numbers
for i in {1..5}; do
  aws sqs receive-message \
    --queue-url $FIFO_QUEUE_URL \
    --max-number-of-messages 1 \
    --wait-time-seconds 2 \
    --output json | python3 -c "import json,sys; m=json.load(sys.stdin); print(f\"Sequence: {m['Messages'][0]['Body']} - SeqNum: {m['Messages'][0].get('SequenceNumber','N/A')}\")" 2>/dev/null
done
```

**Expected Output:**
```
Sequence: {"sequence":1,"message":"Message 1"} - SeqNum: 18898244916664047873
Sequence: {"sequence":2,"message":"Message 2"} - SeqNum: 18898244916664047874
Sequence: {"sequence":3,"message":"Message 3"} - SeqNum: 18898244916664047875
Sequence: {"sequence":4,"message":"Message 4"} - SeqNum: 18898244916664047876
Sequence: {"sequence":5,"message":"Message 5"} - SeqNum: 18898244916664047877
```

**Key Observation:** Messages are received in strict FIFO order (sequence numbers are sequential).

---

## Step 15: Monitor CloudWatch Metrics

View queue metrics in CloudWatch:

```bash
# Get approximate number of messages
aws cloudwatch get-metric-statistics \
  --namespace AWS/SQS \
  --metric-name ApproximateNumberOfMessages \
  --dimensions Name=QueueName,Value=order-notifications-queue \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --output table
```

**Expected Output:**
```
----------------------------------------
|      GetMetricStatistics             |
+------------+-------------------------+
|  Timestamp |       Average           |
+------------+-------------------------+
|  2025-11-20|  0.0                    |
+------------+-------------------------+
```

---

## Step 16: Clean Up Resources

When finished, destroy all resources to avoid charges:

```bash
aws cloudformation delete-stack --stack-name sqs-lab-stack
```

**Verify Deletion:**
```bash
aws cloudformation describe-stacks --stack-name sqs-lab-stack
```
*Note: This command will return an error if the stack has been successfully deleted.*

**Important:** Ensure all messages are processed before destroying queues, as messages will be lost.

---

## Key Takeaways

### Standard Queue Characteristics
- ✅ Unlimited throughput
- ✅ Best-effort ordering (not guaranteed)
- ✅ At-least-once delivery (may have duplicates)
- ✅ Lower cost ($0.40 per million requests)
- ✅ Use for: Logs, metrics, notifications

### FIFO Queue Characteristics
- ✅ Limited throughput (3,000 msg/sec, 300 per MessageGroupId)
- ✅ Strict FIFO ordering (guaranteed)
- ✅ Exactly-once processing (no duplicates)
- ✅ Higher cost ($0.50 per million requests)
- ✅ Use for: Financial transactions, order processing

### Best Practices Demonstrated
1. **Long Polling**: 20-second wait reduces empty responses and costs
2. **Dead Letter Queues**: Configured with `maxReceiveCount: 3` for error handling
3. **Message Attributes**: Used for metadata without parsing body
4. **Immediate Deletion**: Messages deleted after successful processing
5. **Visibility Timeout**: Set appropriately (30 seconds default)

---

## Troubleshooting

### Issue: "Queue does not exist"
**Solution:** Verify queue URLs are correct:
```bash
aws sqs list-queues | grep -E "(order|payment)"
```

### Issue: "Access Denied"
**Solution:** Check IAM permissions:
```bash
aws sqs get-queue-attributes --queue-url $STANDARD_QUEUE_URL --attribute-names All
```

### Issue: Messages not appearing
**Solution:** Check visibility timeout - messages may be in-flight:
```bash
aws sqs get-queue-attributes \
  --queue-url $STANDARD_QUEUE_URL \
  --attribute-names ApproximateNumberOfMessagesNotVisible
```

### Issue: Python import errors
**Solution:** Ensure virtual environment is activated:
```bash
source venv/bin/activate
pip install -r requirements.txt
```

---

## Additional Exercises

1. **Test DLQ**: Simulate message processing failures to trigger DLQ
2. **Batch Operations**: Use `SendMessageBatch` to send up to 10 messages
3. **Message Filtering**: Use message attributes with SNS subscription filters
4. **Cross-Account Access**: Configure queue policies for cross-account access
5. **Encryption**: Enable SSE-KMS encryption on queues

---

## References

- [AWS SQS Documentation](https://docs.aws.amazon.com/sqs/)
- [SQS Best Practices](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-best-practices.html)
- [SQS Pricing](https://aws.amazon.com/sqs/pricing/)
- See `EXAM_TIPS.md` for SAA-C03 exam preparation

---

**Lab Complete!** You've successfully deployed, tested, and understood Amazon SQS queues. Remember to clean up resources when finished.
