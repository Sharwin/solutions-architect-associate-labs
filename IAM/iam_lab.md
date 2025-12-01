# IAM Lab: Secure S3 Access with AssumeRole

## Overview
This lab demonstrates how to use **IAM Roles** to grant temporary access to resources. You will create an IAM User who has *no permissions* to access an S3 bucket directly. Instead, the user must **assume an IAM Role** to gain access. This is a best practice for cross-account access and granting temporary privileges.

## Architecture
1.  **S3 Bucket**: A private bucket (the protected resource).
2.  **IAM User (`IAMLabUser`)**: Represents a developer or application.
3.  **IAM Role (`S3ReadAccessRole`)**: Has permissions to read from the bucket.
4.  **Trust Policy**: Allows `IAMLabUser` to assume `S3ReadAccessRole`.

## Prerequisites
- AWS CLI installed and configured.
- Python 3 installed.

## Deployment
1.  Navigate to the lab directory:
    ```bash
    cd /Users/ivan.bello/Documents/cloudcamp/labs/IAM
    ```
2.  Deploy the CloudFormation stack:
    ```bash
    aws cloudformation deploy \
      --template-file iam_lab.yaml \
      --stack-name IAMLabStack \
      --capabilities CAPABILITY_NAMED_IAM
    ```

## Verification
1.  Create a virtual environment and install dependencies:
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    pip install boto3
    ```
2.  Run the test script:
    ```bash
    python3 test_iam.py
    ```
3.  **Expected Output**:
    - **Step 2**: Direct S3 Access -> **PASS** (Access Denied)
    - **Step 3**: Assume Role -> **PASS** (Success)
    - **Step 4**: Access S3 with Assumed Role -> **PASS** (Success)


## Manual Testing (Console & CLI)

### Option 1: AWS Console (Visual)
1.  **Log in as IAMLabUser**:
    *   **URL**: `https://<Your-Account-ID>.signin.aws.amazon.com/console`
    *   **User**: `IAMLabUser`
    *   **Password**: `Password123!`
2.  **Verify No Access**:
    *   Go to **S3 Console**.
    *   Try to open the bucket `iam-lab-secret-bucket-...`.
    *   You should see **"Insufficient permissions"** or **"Access Denied"**.
3.  **Switch Role**:
    *   Click your username (top right) -> **Switch Role**.
    *   **Account**: Your AWS Account ID.
    *   **Role**: `S3ReadAccessRole`.
    *   **Display Name**: `LabAdmin` (or any name).
    *   Click **Switch Role**.
4.  **Verify Access**:
    *   Go back to S3.
    *   Open the bucket. You should now see the bucket contents (empty, but no error).

### Option 2: AWS CLI (Command Line)
1.  **Create a Profile for the User**:
    ```bash
    # Create access keys for IAMLabUser (if you haven't already via script)
    aws iam create-access-key --user-name IAMLabUser
    
    # Configure a profile (copy the Key ID and Secret from above)
    aws configure --profile lab-user
    ```
2.  **Verify No Access**:
    ```bash
    # Replace with your actual bucket name
    BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name IAMLabStack --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)
    
    aws s3 ls s3://$BUCKET_NAME --profile lab-user
    # Expected: An error occurred (AccessDenied)
    ```
3.  **Assume the Role**:
    ```bash
    ROLE_ARN=$(aws cloudformation describe-stacks --stack-name IAMLabStack --query "Stacks[0].Outputs[?OutputKey=='RoleArn'].OutputValue" --output text)
    
    aws sts assume-role \
        --role-arn $ROLE_ARN \
        --role-session-name ManualTest \
        --profile lab-user
    ```
4.  **Use Temporary Credentials**:
    *   Copy the `AccessKeyId`, `SecretAccessKey`, and `SessionToken` from the output.
    *   Export them as environment variables:
        ```bash
        export AWS_ACCESS_KEY_ID=...
        export AWS_SECRET_ACCESS_KEY=...
        export AWS_SESSION_TOKEN=...
        ```
5.  **Verify Access**:
    ```bash
    aws s3 ls s3://$BUCKET_NAME
    # Expected: (No output if empty, but NO error)
    ```

## Cleanup

To remove all resources:
```bash
aws cloudformation delete-stack --stack-name IAMLabStack
```

## 🎓 SAA-C03 Exam Tips

### 1. IAM Roles vs. IAM Users
*   **IAM Users**: Long-term credentials (Access Keys). Use for humans or on-premise workloads (though Roles are preferred for machines).
*   **IAM Roles**: Temporary credentials. Use for EC2 instances, Lambda functions, and Cross-Account access.
*   **Exam Tip**: If a question asks about "securely accessing S3 from an EC2 instance" or "granting temporary access," the answer is almost always **IAM Role**.

### 2. The "AssumeRole" API
*   When you assume a role, AWS STS (Security Token Service) returns a set of **temporary credentials**:
    *   Access Key ID
    *   Secret Access Key
    *   **Session Token** (This is the key differentiator!)
*   **Exam Tip**: If you see "Session Token" in the logs or requirements, it involves temporary credentials (STS/Roles).

### 3. Trust Policies vs. Identity Policies
*   **Identity Policy**: Attached to a User/Group/Role. Says "What can I do?" (e.g., "I can assume the S3ReadAccessRole").
*   **Trust Policy**: Attached to a **Role**. Says "Who can assume me?" (e.g., "The IAMLabUser is allowed to assume this role").
*   **Exam Tip**: You need BOTH. The User needs permission to `sts:AssumeRole`, AND the Role needs a Trust Policy allowing that User.

### 4. Least Privilege
*   Always grant only the permissions required. In this lab, the User has NO permissions other than `sts:AssumeRole`. The Role has ONLY `s3:ListBucket` and `s3:GetObject`.
