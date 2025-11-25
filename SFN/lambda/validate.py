import json

class OrderValidationError(Exception):
    pass

def lambda_handler(event, context):
    print(f"Validating order: {json.dumps(event)}")
    
    # Basic validation
    if 'order_id' not in event:
        raise OrderValidationError("Missing order_id")
    if 'customer_id' not in event:
        raise OrderValidationError("Missing customer_id")
    if 'amount' not in event or event['amount'] <= 0:
        raise OrderValidationError("Invalid amount")
        
    # Pass through data
    return {
        'order_id': event['order_id'],
        'customer_id': event['customer_id'],
        'amount': event['amount'],
        'status': 'validated'
    }
