#!/usr/bin/env python3
"""
SNS Testing Script
Tests various SNS message publishing scenarios
"""
import boto3
import json
import sys
import time
from botocore.exceptions import ClientError

# Initialize SNS client
sns_client = boto3.client('sns')
sqs_client = boto3.client('sqs')

def get_topic_arn():
    """Get the SNS topic ARN"""
    try:
        response = sns_client.list_topics()
        for topic in response['Topics']:
            if 'ecommerce-order-notifications' in topic['TopicArn']:
                return topic['TopicArn']
        raise Exception("Topic not found")
    except Exception as e:
        print(f"Error finding topic: {e}")
        sys.exit(1)

def publish_message(topic_arn, message_type, message_body):
    """Publish a message to SNS with message attributes"""
    try:
        response = sns_client.publish(
            TopicArn=topic_arn,
            Message=json.dumps(message_body),
            Subject=f"Order Notification: {message_type}",
            MessageAttributes={
                'message_type': {
                    'DataType': 'String',
                    'StringValue': message_type
                }
            }
        )
        print(f"✅ Published {message_type} message - MessageId: {response['MessageId']}")
        return response['MessageId']
    except ClientError as e:
        print(f"❌ Error publishing message: {e}")
        return None

def check_sqs_messages(queue_url):
    """Check for messages in the SQS queue"""
    try:
        response = sqs_client.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=10,
            WaitTimeSeconds=5
        )
        
        if 'Messages' in response:
            print(f"\n📦 Found {len(response['Messages'])} message(s) in warehouse queue:")
            for msg in response['Messages']:
                body = json.loads(msg['Body'])
                if 'Message' in body:
                    sns_message = json.loads(body['Message'])
                    print(f"   Order ID: {sns_message.get('order_id')}")
                    print(f"   Message: {sns_message.get('message')}")
                print(f"   ReceiptHandle: {msg['ReceiptHandle'][:50]}...")
            return response['Messages']
        else:
            print("\n📭 No messages in warehouse queue")
            return []
    except ClientError as e:
        print(f"❌ Error checking SQS queue: {e}")
        return []

def main():
    print("=" * 60)
    print("🚀 SNS Lab Testing Script")
    print("=" * 60)
    
    # Get topic ARN
    topic_arn = get_topic_arn()
    print(f"\n📢 SNS Topic ARN: {topic_arn}\n")
    
    # Test 1: Order Confirmation Email
    print("\n" + "=" * 60)
    print("TEST 1: Publishing Order Confirmation (Email)")
    print("=" * 60)
    message1 = {
        "order_id": "ORD-12345",
        "customer_id": "CUST-001",
        "customer_email": "customer@example.com",
        "order_value": 99.99,
        "message": "Your order has been confirmed!"
    }
    publish_message(topic_arn, "order_confirmation", message1)
    
    # Test 2: Order Tracking SMS
    print("\n" + "=" * 60)
    print("TEST 2: Publishing Order Tracking (SMS)")
    print("=" * 60)
    message2 = {
        "order_id": "ORD-12345",
        "tracking_number": "TRACK-98765",
        "status": "Shipped",
        "message": "Your order has been shipped!"
    }
    publish_message(topic_arn, "order_tracking", message2)
    
    # Test 3: Warehouse Processing (SQS)
    print("\n" + "=" * 60)
    print("TEST 3: Publishing Warehouse Processing (SQS)")
    print("=" * 60)
    message3 = {
        "order_id": "ORD-12345",
        "items": ["Item-A", "Item-B", "Item-C"],
        "priority": "Normal",
        "message": "Order ready for warehouse processing"
    }
    publish_message(topic_arn, "warehouse_processing", message3)
    
    # Wait a moment for message to arrive
    print("\n⏳ Waiting 3 seconds for message to arrive in SQS...")
    time.sleep(3)
    
    # Get queue URL
    try:
        queue_response = sqs_client.get_queue_url(QueueName='warehouse-order-processing')
        queue_url = queue_response['QueueUrl']
        
        # Check for messages
        messages = check_sqs_messages(queue_url)
        
        if messages:
            # Delete messages after reading
            for msg in messages:
                sqs_client.delete_message(
                    QueueUrl=queue_url,
                    ReceiptHandle=msg['ReceiptHandle']
                )
            print("\n✅ Messages processed and deleted from queue")
    except ClientError as e:
        print(f"⚠️  Could not check SQS queue: {e}")
    
    # Test 4: Analytics Processing (Lambda)
    print("\n" + "=" * 60)
    print("TEST 4: Publishing Analytics Data (Lambda)")
    print("=" * 60)
    message4 = {
        "order_id": "ORD-12345",
        "customer_id": "CUST-001",
        "order_value": 99.99,
        "timestamp": "2024-01-15T10:30:00Z",
        "message": "Analytics data for processing"
    }
    publish_message(topic_arn, "analytics", message4)
    
    print("\n⏳ Waiting 5 seconds for Lambda to process...")
    time.sleep(5)
    
    # Check CloudWatch Logs
    print("\n📊 Check CloudWatch Logs for Lambda execution:")
    print(f"   Log Group: /aws/lambda/sns-analytics-processor")
    
    print("\n" + "=" * 60)
    print("✅ Testing Complete!")
    print("=" * 60)
    print("\n📧 Check your email for order confirmation")
    print("📱 Check your phone for SMS notification (if configured)")
    print("📋 Check CloudWatch Logs for Lambda execution")
    print("📦 Check SQS queue for warehouse messages")

if __name__ == "__main__":
    main()

