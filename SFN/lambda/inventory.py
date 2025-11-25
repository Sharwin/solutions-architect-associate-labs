import json
import random

def lambda_handler(event, context):
    print(f"Checking inventory for order: {event['order_id']}")
    
    # Simulate inventory check
    # In a real scenario, this would check DynamoDB
    
    # Simulate random out of stock (10% chance) for educational purposes? 
    # Let's keep it simple for now and assume success unless we want to demo error handling specifically.
    
    return {
        'order_id': event['order_id'],
        'customer_id': event['customer_id'],
        'amount': event['amount'],
        'status': 'inventory_confirmed'
    }
