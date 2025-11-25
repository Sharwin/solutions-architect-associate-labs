#!/usr/bin/env python3
"""
SQS Consumer Script
Receives and processes messages from SQS queues
"""

import boto3
import json
import sys
import time

def process_message(queue_name, message):
    """Process a single message"""
    body = json.loads(message['Body'])
    
    print(f"\n📨 Processing message from {queue_name}:")
    print(f"   Message ID: {message['MessageId']}")
    print(f"   Receipt Handle: {message['ReceiptHandle'][:50]}...")
    print(f"   Body: {json.dumps(body, indent=2)}")
    
    if 'MessageAttributes' in message:
        print(f"   Attributes: {message['MessageAttributes']}")
    
    # Simulate processing
    time.sleep(1)
    print(f"   ✅ Message processed successfully!")
    
    return True

def consume_queue(sqs_client, queue_url, queue_name, max_messages=10):
    """Consume messages from a queue"""
    print(f"\n{'='*60}")
    print(f"📬 Consuming from: {queue_name}")
    print(f"{'='*60}")
    
    messages_processed = 0
    
    while messages_processed < max_messages:
        try:
            # Receive messages with long polling (20 seconds)
            response = sqs_client.receive_message(
                QueueUrl=queue_url,
                MaxNumberOfMessages=10,  # Max 10 messages per request
                WaitTimeSeconds=20,      # Long polling
                MessageAttributeNames=['All']
            )
            
            if 'Messages' not in response or len(response['Messages']) == 0:
                print(f"   ⏳ No messages available. Waiting...")
                if messages_processed > 0:
                    break  # Exit if we've processed some messages and now queue is empty
                continue
            
            for message in response['Messages']:
                # Process the message
                success = process_message(queue_name, message)
                
                if success:
                    # Delete message from queue after successful processing
                    sqs_client.delete_message(
                        QueueUrl=queue_url,
                        ReceiptHandle=message['ReceiptHandle']
                    )
                    messages_processed += 1
                    print(f"   🗑️  Message deleted from queue")
            
        except KeyboardInterrupt:
            print("\n\n⚠️  Interrupted by user")
            break
        except Exception as e:
            print(f"❌ Error consuming messages: {e}")
            break
    
    print(f"\n✅ Processed {messages_processed} messages from {queue_name}")
    return messages_processed

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 consumer.py <standard_queue_url> <fifo_queue_url> [max_messages]")
        print("Example: python3 consumer.py https://sqs.us-east-1.amazonaws.com/123456789/order-notifications-queue https://sqs.us-east-1.amazonaws.com/123456789/payment-processing-queue.fifo 10")
        sys.exit(1)
    
    standard_queue_url = sys.argv[1]
    fifo_queue_url = sys.argv[2]
    max_messages = int(sys.argv[3]) if len(sys.argv) > 3 else 10
    
    sqs_client = boto3.client('sqs')
    
    print("=" * 60)
    print("📥 SQS Consumer - Processing Messages")
    print("=" * 60)
    
    # Consume from Standard Queue
    consume_queue(sqs_client, standard_queue_url, "Standard Queue (Order Notifications)", max_messages)
    
    # Consume from FIFO Queue
    consume_queue(sqs_client, fifo_queue_url, "FIFO Queue (Payment Processing)", max_messages)
    
    print("\n" + "=" * 60)
    print("✅ Consumer finished!")
    print("=" * 60)

if __name__ == "__main__":
    main()

