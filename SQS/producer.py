#!/usr/bin/env python3
"""
SQS Producer Script
Sends messages to both Standard and FIFO queues
"""

import boto3
import json
import sys
import time
from datetime import datetime

def send_to_standard_queue(sqs_client, queue_url, order_id, customer_email, order_total):
    """Send message to Standard Queue"""
    message_body = {
        "order_id": order_id,
        "customer_email": customer_email,
        "order_total": order_total,
        "timestamp": datetime.now().isoformat(),
        "type": "order_notification"
    }
    
    try:
        response = sqs_client.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(message_body),
            MessageAttributes={
                'OrderType': {
                    'StringValue': 'standard',
                    'DataType': 'String'
                },
                'OrderTotal': {
                    'StringValue': str(order_total),
                    'DataType': 'Number'
                }
            }
        )
        print(f"✅ Standard Queue: Message sent! MessageId: {response['MessageId']}")
        return response
    except Exception as e:
        print(f"❌ Error sending to Standard Queue: {e}")
        return None

def send_to_fifo_queue(sqs_client, queue_url, order_id, customer_email, order_total, payment_id):
    """Send message to FIFO Queue with Message Group ID"""
    message_body = {
        "order_id": order_id,
        "payment_id": payment_id,
        "customer_email": customer_email,
        "order_total": order_total,
        "timestamp": datetime.now().isoformat(),
        "type": "payment_processing"
    }
    
    try:
        response = sqs_client.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(message_body),
            MessageGroupId=f"payment-{order_id}",  # Required for FIFO
            MessageDeduplicationId=f"payment-{payment_id}",  # For deduplication
            MessageAttributes={
                'PaymentType': {
                    'StringValue': 'credit_card',
                    'DataType': 'String'
                },
                'Amount': {
                    'StringValue': str(order_total),
                    'DataType': 'Number'
                }
            }
        )
        print(f"✅ FIFO Queue: Message sent! MessageId: {response['MessageId']}")
        return response
    except Exception as e:
        print(f"❌ Error sending to FIFO Queue: {e}")
        return None

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 producer.py <standard_queue_url> <fifo_queue_url>")
        print("Example: python3 producer.py https://sqs.us-east-1.amazonaws.com/123456789/order-notifications-queue https://sqs.us-east-1.amazonaws.com/123456789/payment-processing-queue.fifo")
        sys.exit(1)
    
    standard_queue_url = sys.argv[1]
    fifo_queue_url = sys.argv[2]
    
    sqs_client = boto3.client('sqs')
    
    print("=" * 60)
    print("🚀 SQS Producer - Sending Messages")
    print("=" * 60)
    
    # Send multiple messages to demonstrate behavior
    orders = [
        {"order_id": "ORD-001", "email": "customer1@example.com", "total": 99.99, "payment_id": "PAY-001"},
        {"order_id": "ORD-002", "email": "customer2@example.com", "total": 149.50, "payment_id": "PAY-002"},
        {"order_id": "ORD-003", "email": "customer3@example.com", "total": 75.25, "payment_id": "PAY-003"},
    ]
    
    print("\n📦 Sending to Standard Queue (Order Notifications)...")
    for order in orders:
        send_to_standard_queue(
            sqs_client, 
            standard_queue_url,
            order["order_id"],
            order["email"],
            order["total"]
        )
        time.sleep(0.5)
    
    print("\n💳 Sending to FIFO Queue (Payment Processing)...")
    for order in orders:
        send_to_fifo_queue(
            sqs_client,
            fifo_queue_url,
            order["order_id"],
            order["email"],
            order["total"],
            order["payment_id"]
        )
        time.sleep(0.5)
    
    print("\n" + "=" * 60)
    print("✅ All messages sent successfully!")
    print("=" * 60)

if __name__ == "__main__":
    main()

