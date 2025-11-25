import json

def lambda_handler(event, context):
    print(f"Processing payment for order: {event['order_id']} Amount: {event['amount']}")
    
    # Simulate payment processing
    
    return {
        'order_id': event['order_id'],
        'customer_id': event['customer_id'],
        'amount': event['amount'],
        'status': 'payment_processed',
        'transaction_id': 'tx-12345-67890'
    }
