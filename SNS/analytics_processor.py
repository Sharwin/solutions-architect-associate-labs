import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda function to process analytics messages from SNS
    """
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Process SNS records
    for record in event.get('Records', []):
        if record.get('EventSource') == 'aws:sns':
            sns_message = json.loads(record['Sns']['Message'])
            logger.info(f"Processing analytics message: {sns_message}")
            
            # Simulate analytics processing
            order_id = sns_message.get('order_id', 'N/A')
            customer_id = sns_message.get('customer_id', 'N/A')
            order_value = sns_message.get('order_value', 0)
            
            logger.info(f"Analytics processed - Order ID: {order_id}, Customer: {customer_id}, Value: ${order_value}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Analytics processing completed successfully')
    }

