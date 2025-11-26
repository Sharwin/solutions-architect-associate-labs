import boto3
import json
import time

import sys

def get_state_machine_arn():
    cf_client = boto3.client('cloudformation', region_name='us-east-1')
    try:
        response = cf_client.describe_stacks(StackName='sfn-lab-stack')
        outputs = response['Stacks'][0]['Outputs']
        for output in outputs:
            if output['OutputKey'] == 'StateMachineArn':
                return output['OutputValue']
        print("StateMachineArn output not found in CloudFormation stack.")
        sys.exit(1)
    except Exception as e:
        print(f"Error getting CloudFormation output: {e}")
        sys.exit(1)

def run_test(sfn_client, state_machine_arn, input_payload, test_name):
    print(f"\n--- Starting Test: {test_name} ---")
    print(f"Input: {json.dumps(input_payload, indent=2)}")
    
    response = sfn_client.start_execution(
        stateMachineArn=state_machine_arn,
        input=json.dumps(input_payload)
    )
    
    execution_arn = response['executionArn']
    print(f"Execution started: {execution_arn}")
    
    # Poll for completion
    while True:
        status_response = sfn_client.describe_execution(executionArn=execution_arn)
        status = status_response['status']
        print(f"Status: {status}")
        
        if status in ['SUCCEEDED', 'FAILED', 'TIMED_OUT', 'ABORTED']:
            break
        time.sleep(2)
        
    print(f"Final Status: {status}")
    if 'output' in status_response:
        print(f"Output: {status_response['output']}")
    elif 'error' in status_response: # For failed executions
         print(f"Error: {status_response.get('error')}")
         print(f"Cause: {status_response.get('cause')}")

def main():
    state_machine_arn = get_state_machine_arn()
    print(f"State Machine ARN: {state_machine_arn}")
    
    sfn_client = boto3.client('stepfunctions', region_name='us-east-1')
    
    # Test 1: Valid Order
    valid_order = {
        "order_id": "ord-123",
        "customer_id": "cust-999",
        "amount": 150
    }
    run_test(sfn_client, state_machine_arn, valid_order, "Valid Order")
    
    # Test 2: Invalid Order (Missing Amount)
    invalid_order = {
        "order_id": "ord-bad",
        "customer_id": "cust-999"
    }
    run_test(sfn_client, state_machine_arn, invalid_order, "Invalid Order (Expect Fail)")

if __name__ == "__main__":
    main()
