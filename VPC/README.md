# AWS Networking Lab: VPC, Subnets, & SSM

## Overview
This lab demonstrates how to build a custom Virtual Private Cloud (VPC) on AWS using CloudFormation. You will create a network environment with both public and private subnets, configure routing, and deploy instances to verify connectivity using **AWS Systems Manager (SSM)** and **ICMP (Ping)**.

## Architecture
- **VPC**: A custom isolated network (10.0.0.0/16).
- **Public Subnet**: Connected to the Internet via an Internet Gateway (10.0.1.0/24).
- **Private Subnet**: Isolated subnet (10.0.2.0/24).
- **Internet Gateway (IGW)**: Enables internet access for the public subnet.
- **NAT Gateway**: Enables the private subnet to access the internet (required for SSM) without exposing it to incoming traffic.
- **Route Tables**: Controls traffic flow for each subnet.
- **EC2 Instances**:
    - **WebServer**: In the Public Subnet.
    - **PrivateServer**: In the Private Subnet, accessed via SSM.
- **Security Groups**: Configured to allow HTTP, SSH, and ICMP.

## Prerequisites
- AWS CLI installed and configured.
- An active AWS account.
- **Session Manager Plugin** for AWS CLI installed (optional, for CLI access).

## Deployment Steps

1.  **Deploy the Stack**:
    Run the following command in your terminal:
    ```bash
    aws cloudformation deploy \
      --template-file vpc-lab.yaml \
      --stack-name vpc-lab-stack \
      --capabilities CAPABILITY_IAM
    ```

2.  **Wait for Completion**:
    The deployment may take a few minutes (NAT Gateway creation takes time). You can check the status with:
    ```bash
    aws cloudformation describe-stacks --stack-name vpc-lab-stack
    ```

3.  **Get Outputs**:
    Retrieve the Instance IDs and IPs:
    ```bash
    aws cloudformation describe-stacks \
      --stack-name vpc-lab-stack \
      --query "Stacks[0].Outputs" \
      --output table
    ```

## Verification

### 1. Web Server Connectivity
Test the public web server to verify it is serving traffic.

**Command:**
```bash
curl <WebServerUrl>
# Example: curl http://3.227.229.17
```

**Expected Output:**
```html
<h1>Hello from the VPC Lab!</h1><p>This instance is in the Public Subnet.</p>
```

### 2. Connect to Private Instance via SSM
You can connect to the private instance using AWS Systems Manager Session Manager.

**Option A: AWS Console**
1. Go to the EC2 Console.
2. Select the `PrivateServer` instance.
3. Click **Connect**.
4. Select the **Session Manager** tab and click **Connect**.

**Option B: AWS CLI** (Requires Session Manager Plugin)
```bash
aws ssm start-session --target <PrivateServerInstanceID>
```

### 3. Verify Ping Connectivity (From Private Instance)
Once connected to the **PrivateServer** (via SSM), run the following tests:

#### A. Ping the Internet (Verify NAT Gateway)
This confirms the Private Instance can reach the internet via the NAT Gateway.

**Command:**
```bash
ping -c 3 google.com
```

**Expected Output:**
```text
PING google.com (142.251.179.139) 56(84) bytes of data.
64 bytes from pd-in-f139.1e100.net (142.251.179.139): icmp_seq=1 ttl=105 time=2.66 ms
64 bytes from pd-in-f139.1e100.net (142.251.179.139): icmp_seq=2 ttl=105 time=2.22 ms
64 bytes from pd-in-f139.1e100.net (142.251.179.139): icmp_seq=3 ttl=105 time=2.24 ms

--- google.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
```

#### B. Ping the Public Instance (Verify Private -> Public)
This confirms the Private Instance can reach the Web Server in the Public Subnet.

**Command:**
```bash
# Replace with your Web Server's Private IP
ping -c 3 10.0.1.79
```

**Expected Output:**
```text
PING 10.0.1.79 (10.0.1.79) 56(84) bytes of data.
64 bytes from 10.0.1.79: icmp_seq=1 ttl=127 time=2.24 ms
64 bytes from 10.0.1.79: icmp_seq=2 ttl=127 time=1.29 ms
64 bytes from 10.0.1.79: icmp_seq=3 ttl=127 time=1.08 ms

--- 10.0.1.79 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
```

### 4. Verify Ping from Public to Private
Connect to the **WebServer** (via SSH or SSM) and ping the Private Instance.

**Command:**
```bash
# Replace with your Private Server's Private IP
ping -c 3 10.0.2.116
```

**Expected Output:**
```text
PING 10.0.2.116 (10.0.2.116) 56(84) bytes of data.
64 bytes from 10.0.2.116: icmp_seq=1 ttl=127 time=0.744 ms
64 bytes from 10.0.2.116: icmp_seq=2 ttl=127 time=1.06 ms
64 bytes from 10.0.2.116: icmp_seq=3 ttl=127 time=0.811 ms

--- 10.0.2.116 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
```

### 5. Useful SSM Commands Reference

Here are some useful AWS CLI commands for managing and interacting with your instances via Systems Manager.

#### Check Instance Status
Verify that your instances are connected to SSM and ready to receive commands.
```bash
aws ssm describe-instance-information --output table
```

#### Start a Session (Interactive Shell)
Connect to an instance interactively (requires Session Manager Plugin).
```bash
aws ssm start-session --target <InstanceID>
```

#### Run a Remote Command (Send-Command)
Execute a command on one or more instances without logging in.

**Example: Check Disk Space**
```bash
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=instanceids,Values=<InstanceID>" \
  --parameters 'commands=["df -h"]'
```

**Example: Ping Google (as used in verification)**
```bash
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=instanceids,Values=<InstanceID>" \
  --parameters 'commands=["ping -c 3 google.com"]'
```

#### Check Command Status
List recent command executions to see if they Succeeded, Failed, or are Pending.
```bash
aws ssm list-command-invocations \
  --details \
  --query "CommandInvocations[*].[CommandId,InstanceId,Status,CommandPlugins[0].Output]" \
  --output table
```

#### Get Specific Command Output
Retrieve the full output of a specific command execution.
```bash
aws ssm get-command-invocation \
  --command-id <CommandID> \
  --instance-id <InstanceID> \
  --query "StandardOutputContent" \
  --output text
```

## Cleanup
To remove all resources created by this lab:
```bash
aws cloudformation delete-stack --stack-name vpc-lab-stack
```
