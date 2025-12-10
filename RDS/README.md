# RDS Lab: Migrating WordPress Database to RDS

This lab demonstrates how to deploy a WordPress site running on an EC2 instance with a local MariaDB database and then migrate that database to a managed Amazon RDS instance.

## Architecture

- **VPC**: Custom VPC with Public and Private subnets.
- **ALB**: Application Load Balancer in Public Subnets (access to Internet).
- **EC2**: Web Server running Apache/PHP/MariaDB in Private Subnet (access only via ALB and SSM).
- **RDS**: Managed MariaDB instance in Private Subnets.
- **SSM**: AWS Systems Manager for secure shell access (no SSH keys needed).

## Prerequisites

- AWS CLI configured with appropriate credentials.
- AWS Account with permissions to create VPC, EC2, RDS, IAM resources.

## Deployment

1. **Deploy the CloudFormation Stack**:
   ```bash
   aws cloudformation deploy \
     --template-file rds-lab.yaml \
     --stack-name rds-lab \
     --capabilities CAPABILITY_NAMED_IAM
   ```
   *This process typically takes 10-15 minutes (RDS provisioning takes time).*

2. **Verify Deployment**:
   - Get the ALB DNS Name:
     ```bash
     aws cloudformation describe-stacks --stack-name rds-lab --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNS'].OutputValue" --output text
     ```
   - Open that URL in your browser. You should see the WordPress installation screen (or the site if already configured).

## Lab Challenge: Migrate DB to RDS

Your Goal: Move the WordPress database from the local EC2 instance to the new RDS instance.

### Step 1: Connect to EC2 via SSM
Since the instance is in a private subnet, we use Systems Manager Session Manager.

1. Get the Instance ID:
   ```bash
   aws cloudformation describe-stacks --stack-name rds-lab --query "Stacks[0].Outputs[?OutputKey=='WebInstanceId'].OutputValue" --output text
   ```
2. Start a session (requires Session Manager Plugin):
   ```bash
   aws ssm start-session --target <INSTANCE_ID>
   ```
   *Alternatively, use the AWS Console -> EC2 -> Select Instance -> Connect -> Session Manager.*

### Step 2: Export Local Database
Once logged in to the EC2 instance shell:
```bash
sudo su -
mysqldump -u root -prootpassword wordpress > wordpress.sql
```

### Step 3: Connect and Import to RDS
1. Get the RDS Endpoint Address (check CloudFormation Outputs or Console).
2. Connect to RDS to verify connectivity (password is `password123` by default per template):
   ```bash
   mysql -h <RDS_ENDPOINT> -u admin -p
   # Enter password: password123
   ```
   *Type `exit` to return to shell.*
3. Import the dump to RDS:
   ```bash
   mysql -h <RDS_ENDPOINT> -u admin -p wordpressdb < wordpress.sql
   ```
   *Note: `wordpressdb` is the default DB name created by RDS in our template.*

### Step 4: Update WordPress Configuration
1. Edit `wp-config.php`:
   ```bash
   cd /var/www/html
   nano wp-config.php
   ```
2. Update the following values:
   - `DB_NAME`: Change 'wordpress' to 'wordpressdb'
   - `DB_USER`: Change 'wordpress' to 'admin'
   - `DB_PASSWORD`: Change 'wordpress-pass' to 'password123'
   - `DB_HOST`: Change 'localhost' to the **RDS Endpoint Address**

### Step 5: Stop Local Database & Verify
1. Stop the local MariaDB service to prove we aren't using it:
   ```bash
   systemctl stop mariadb
   systemctl disable mariadb
   ```
2. Restart Apache just in case:
   ```bash
   systemctl restart httpd
   ```
3. Refresh your browser (ALB URL). The site should still work!

## Cleanup

To remove all resources:
```bash
aws cloudformation delete-stack --stack-name rds-lab
```
