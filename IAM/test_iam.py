import boto3
import json
import time
import sys
from botocore.exceptions import ClientError

def get_stack_outputs(stack_name):
    cf = boto3.client('cloudformation')
    response = cf.describe_stacks(StackName=stack_name)
    outputs = {}
    for output in response['Stacks'][0]['Outputs']:
        outputs[output['OutputKey']] = output['OutputValue']
    return outputs

def test_iam_scenario():
    stack_name = 'IAMLabStack'
    print(f"Fetching outputs for stack: {stack_name}...")
    try:
        outputs = get_stack_outputs(stack_name)
    except Exception as e:
        print(f"Error fetching stack outputs: {e}")
        return

    bucket_name = outputs['BucketName']
    user_name = 'IAMLabUser' # Hardcoded as per CFN
    role_arn = outputs['RoleArn']

    print(f"Target Bucket: {bucket_name}")
    print(f"Target User: {user_name}")
    print(f"Target Role: {role_arn}")

    # 1. Create Access Key for the User (Simulating login)
    iam = boto3.client('iam')
    print(f"\n[Step 1] Creating Access Key for {user_name}...")
    try:
        key_response = iam.create_access_key(UserName=user_name)
        access_key_id = key_response['AccessKey']['AccessKeyId']
        secret_access_key = key_response['AccessKey']['SecretAccessKey']
        print("Access Key Created.")
        
        # Wait for propagation
        print("Waiting 10s for credential propagation...")
        time.sleep(10)
    except ClientError as e:
        print(f"Error creating access key: {e}")
        return

    try:
        # Create a session as the IAM User
        user_session = boto3.Session(
            aws_access_key_id=access_key_id,
            aws_secret_access_key=secret_access_key
        )
        
        # 2. Try to access S3 directly (Should Fail)
        print("\n[Step 2] Attempting Direct S3 Access (Expect: AccessDenied)...")
        s3_client = user_session.client('s3')
        try:
            s3_client.list_objects_v2(Bucket=bucket_name)
            print("FAIL: Direct access succeeded (Unexpected).")
        except ClientError as e:
            if e.response['Error']['Code'] == 'AccessDenied':
                print("PASS: Direct access denied as expected.")
            else:
                print(f"FAIL: Unexpected error: {e}")

        # 3. Assume the Role
        print(f"\n[Step 3] Assuming Role: {role_arn}...")
        sts_client = user_session.client('sts')
        try:
            assume_role_response = sts_client.assume_role(
                RoleArn=role_arn,
                RoleSessionName='LabSession'
            )
            temp_creds = assume_role_response['Credentials']
            print("PASS: Role assumed successfully.")
        except ClientError as e:
            print(f"FAIL: Could not assume role: {e}")
            raise e

        # 4. Access S3 with Temporary Credentials (Should Succeed)
        print("\n[Step 4] Attempting S3 Access with Assumed Role (Expect: Success)...")
        role_session = boto3.Session(
            aws_access_key_id=temp_creds['AccessKeyId'],
            aws_secret_access_key=temp_creds['SecretAccessKey'],
            aws_session_token=temp_creds['SessionToken']
        )
        s3_role_client = role_session.client('s3')
        
        try:
            s3_role_client.list_objects_v2(Bucket=bucket_name)
            print("PASS: Access succeeded with assumed role.")
        except ClientError as e:
            print(f"FAIL: Access failed with assumed role: {e}")

    finally:
        # 5. Cleanup
        print(f"\n[Step 5] Cleaning up Access Key for {user_name}...")
        try:
            iam.delete_access_key(UserName=user_name, AccessKeyId=access_key_id)
            print("Cleanup Complete.")
        except Exception as e:
            print(f"Error deleting access key: {e}")

if __name__ == '__main__':
    test_iam_scenario()
