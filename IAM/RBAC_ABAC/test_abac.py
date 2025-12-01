import boto3
import time
from botocore.exceptions import ClientError

def get_stack_outputs(stack_name):
    cf = boto3.client('cloudformation')
    response = cf.describe_stacks(StackName=stack_name)
    outputs = {}
    for output in response['Stacks'][0]['Outputs']:
        outputs[output['OutputKey']] = output['OutputValue']
    return outputs

def test_access(user_name, access_key, secret_key, bucket_name, expected_result):
    print(f"Testing {user_name} -> {bucket_name} (Expect: {expected_result})...")
    
    # Get Session Token to ensure tags are propagated
    sts = boto3.client(
        'sts',
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key
    )
    try:
        token = sts.get_session_token()
        creds = token['Credentials']
        
        session = boto3.Session(
            aws_access_key_id=creds['AccessKeyId'],
            aws_secret_access_key=creds['SecretAccessKey'],
            aws_session_token=creds['SessionToken']
        )
    except Exception as e:
        print(f"  FAIL: Could not get session token: {e}")
        return

    s3 = session.client('s3')
    
    try:
        # Try to read the secret file
        s3.get_object(Bucket=bucket_name, Key='secret.txt')
        if expected_result == "SUCCESS":
            print("  PASS: Access Granted.")
        else:
            print("  FAIL: Access Granted (Unexpected).")
    except ClientError as e:
        if expected_result == "FAIL" and e.response['Error']['Code'] == 'AccessDenied':
            print("  PASS: Access Denied.")
        elif expected_result == "SUCCESS":
            print(f"  FAIL: Access Denied (Unexpected): {e}")
        else:
            print(f"  FAIL: Unexpected Error: {e}")

def run_abac_test():
    stack_name = 'ABACLabStack'
    print(f"Fetching outputs for stack: {stack_name}...")
    try:
        outputs = get_stack_outputs(stack_name)
    except Exception as e:
        print(f"Error fetching stack outputs: {e}")
        return

    red_bucket = outputs['RedBucketName']
    blue_bucket = outputs['BlueBucketName']
    red_user = 'RedUser'
    blue_user = 'BlueUser'

    iam = boto3.client('iam')
    
    # Create Keys
    keys = {}
    for user in [red_user, blue_user]:
        print(f"Creating key for {user}...")
        try:
            resp = iam.create_access_key(UserName=user)
            keys[user] = resp['AccessKey']
        except Exception as e:
            print(f"Error creating key for {user}: {e}")
            return

    print("Waiting 10s for propagation...")
    time.sleep(10)

    try:
        # Test Red User
        print("\n--- Red User Tests ---")
        test_access(red_user, keys[red_user]['AccessKeyId'], keys[red_user]['SecretAccessKey'], red_bucket, "SUCCESS")
        test_access(red_user, keys[red_user]['AccessKeyId'], keys[red_user]['SecretAccessKey'], blue_bucket, "FAIL")

        # Test Blue User
        print("\n--- Blue User Tests ---")
        test_access(blue_user, keys[blue_user]['AccessKeyId'], keys[blue_user]['SecretAccessKey'], blue_bucket, "SUCCESS")
        test_access(blue_user, keys[blue_user]['AccessKeyId'], keys[blue_user]['SecretAccessKey'], red_bucket, "FAIL")

    finally:
        # Cleanup
        print("\nCleaning up keys...")
        for user in [red_user, blue_user]:
            if user in keys:
                iam.delete_access_key(UserName=user, AccessKeyId=keys[user]['AccessKeyId'])

if __name__ == '__main__':
    run_abac_test()
