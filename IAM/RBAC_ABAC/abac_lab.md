# IAM Lab: RBAC vs ABAC (Attribute-Based Access Control)

## Overview
This lab demonstrates the power of **Attribute-Based Access Control (ABAC)**.
Instead of creating separate policies for every project (RBAC), we use a **single policy** that grants access based on matching tags.

## Architecture
1.  **S3 Buckets**:
    *   `RedBucket` (Tagged `Project=Red`)
    *   `BlueBucket` (Tagged `Project=Blue`)
2.  **IAM Users**:
    *   `RedUser` (Tagged `Project=Red`)
    *   `BlueUser` (Tagged `Project=Blue`)
3.  **ABAC Policy**:
    *   Allows `s3:GetObject` **ONLY IF** `aws:PrincipalTag/Project` matches `s3:ExistingObjectTag/Project`.

## Prerequisites
- AWS CLI installed and configured.
- Python 3 installed.

## Deployment
1.  Navigate to the lab directory:
    ```bash
    cd /Users/ivan.bello/Documents/cloudcamp/labs/IAM/RBAC_ABAC
    ```
2.  Deploy the CloudFormation stack:
    ```bash
    aws cloudformation deploy \
      --template-file abac_lab.yaml \
      --stack-name ABACLabStack \
      --capabilities CAPABILITY_NAMED_IAM
    ```
3.  **Important**: Upload tagged objects for testing (S3 Object Tags are required for ABAC on GetObject):
    ```bash
    # Create a dummy file
    echo "Secret Data" > secret.txt
    
    # Get Bucket Names
    RED_BUCKET=$(aws cloudformation describe-stacks --stack-name ABACLabStack --query "Stacks[0].Outputs[?OutputKey=='RedBucketName'].OutputValue" --output text)
    BLUE_BUCKET=$(aws cloudformation describe-stacks --stack-name ABACLabStack --query "Stacks[0].Outputs[?OutputKey=='BlueBucketName'].OutputValue" --output text)
    
    # Upload and Tag
    aws s3 cp secret.txt s3://$RED_BUCKET/secret.txt
    aws s3api put-object-tagging --bucket $RED_BUCKET --key secret.txt --tagging 'TagSet=[{Key=Project,Value=Red}]'
    
    aws s3 cp secret.txt s3://$BLUE_BUCKET/secret.txt
    aws s3api put-object-tagging --bucket $BLUE_BUCKET --key secret.txt --tagging 'TagSet=[{Key=Project,Value=Blue}]'
    ```

## Verification
1.  Run the test script:
    ```bash
    source ../venv/bin/activate
    python3 test_abac.py
    ```
2.  **Expected Output**:
    *   **RedUser** -> RedBucket: **PASS** (Access Granted)
    *   **RedUser** -> BlueBucket: **PASS** (Access Denied)
    *   **BlueUser** -> BlueBucket: **PASS** (Access Granted)
    *   **BlueUser** -> RedBucket: **PASS** (Access Denied)

    *   **BlueUser** -> RedBucket: **PASS** (Access Denied)

### Manual Testing (CLI)
Since ABAC relies on tags being present in the session, you must use **Temporary Credentials** (via `sts:GetSessionToken`) even for IAM Users.

1.  **Create Access Keys for RedUser**:
    ```bash
    aws iam create-access-key --user-name RedUser
    # Note the AccessKeyId and SecretAccessKey
    ```

2.  **Configure Credentials**:
    Export the long-term credentials you just created:
    ```bash
    export AWS_ACCESS_KEY_ID=AKIA...       # Replace with your Key ID
    export AWS_SECRET_ACCESS_KEY=Secret... # Replace with your Secret
    ```

3.  **Get a Session Token (The "Tag Injection" Step)**:
    Now run the command (it will use the exported variables):
    ```bash
    aws sts get-session-token
    ```

4.  **Export Temporary Credentials**:
    The command above outputs a JSON with `AccessKeyId`, `SecretAccessKey`, and `SessionToken`.
    **Overwrite** your environment variables with these new values:
    ```bash
    export AWS_ACCESS_KEY_ID=...      # From Session Token output
    export AWS_SECRET_ACCESS_KEY=...  # From Session Token output
    export AWS_SESSION_TOKEN=...      # From Session Token output
    ```

5.  **Test Access (As RedUser)**:
    ```bash
    # Try to read RedBucket (Should Work)
    aws s3 cp s3://$RED_BUCKET/secret.txt -
    
    # Try to read BlueBucket (Should Fail)
    aws s3 cp s3://$BLUE_BUCKET/secret.txt -
    ```

5.  **Unset Credentials**:
    ```bash
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
    ```

## Cleanup

```bash
# Empty buckets first
aws s3 rm s3://$RED_BUCKET --recursive
aws s3 rm s3://$BLUE_BUCKET --recursive

# Delete Stack
aws cloudformation delete-stack --stack-name ABACLabStack
```

## 🎓 SAA-C03 Exam Tips

### 1. RBAC vs. ABAC
*   **RBAC (Role-Based)**: "I allow the *Managers* role to access the *Finance* bucket."
    *   **Pro**: Simple for small scale.
    *   **Con**: If you add a "Marketing" team, you need a NEW policy.
*   **ABAC (Attribute-Based)**: "I allow access if the User's Department tag matches the Resource's Department tag."
    *   **Pro**: **Scales infinitely**. You add a new team by just tagging them; NO policy changes needed.
    *   **Con**: More complex to set up initially.

### 2. Condition Keys
*   `aws:PrincipalTag/<Key>`: The tag on the User/Role making the request.
*   `s3:ResourceTag/<Key>`: The tag on the Bucket (for ListBucket).
*   `s3:ExistingObjectTag/<Key>`: The tag on the Object (for GetObject).
*   **Exam Tip**: If a scenario asks about "minimizing policy management overhead" for a growing number of teams, the answer is **ABAC** (using tags).
