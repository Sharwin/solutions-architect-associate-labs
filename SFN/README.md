# AWS Step Functions Lab: Order Processing Workflow

This lab demonstrates a serverless order processing workflow using **AWS Step Functions** and **AWS Lambda**. It is designed to help you prepare for the **AWS Certified Solutions Architect - Associate (SAA-C03)** exam by providing hands-on experience with orchestration, state machine definition, and error handling.

## 🏗️ Architecture

The workflow orchestrates three Lambda functions to process an order:

1.  **ValidateOrder**: Checks if the order has valid data (Order ID, Customer ID, Amount).
    *   *Retry Policy*: Retries twice on task failure.
    *   *Catch Policy*: Catches `OrderValidationError` and routes to `OrderFailed`.
2.  **CheckInventory**: Simulates checking stock availability.
3.  **ProcessPayment**: Simulates charging the customer.

**Success Path**: `ValidateOrder` -> `CheckInventory` -> `ProcessPayment` -> `OrderSucceeded`
**Failure Path**: `ValidateOrder` (Error) -> `OrderFailed`

## 🎓 SAA-C03 Exam Concepts

### 1. Step Functions vs. SWF vs. SQS
*   **Step Functions**: The recommended service for orchestrating microservices and serverless workflows. It visualizes the workflow and manages state.
*   **SWF (Simple Workflow Service)**: Legacy service. Only use if you need manual tasks or external signals not supported by Step Functions (rare).
*   **SQS (Simple Queue Service)**: Decouples components but doesn't orchestrate them. It's for message buffering, not workflow logic.

### 2. Standard vs. Express Workflows
*   **Standard (Used here)**: Long-running (up to 1 year), exactly-once execution, visual history. Good for order processing, IT automation.
*   **Express**: High-volume, short duration (up to 5 mins), at-least-once execution. Good for IoT data ingestion, streaming data.

### 3. Error Handling
*   **Retry**: Automatically retry failed steps (e.g., transient network issues). You can configure `IntervalSeconds`, `MaxAttempts`, and `BackoffRate`.
*   **Catch**: Handle specific errors and transition to a fallback state (e.g., `OrderFailed`), acting like a try-catch block.

### 4. Amazon States Language (ASL)
*   JSON-based language used to define the state machine.
*   **Task State**: Do some work (invoke Lambda, call API).
*   **Choice State**: Branch logic based on input.
*   **Wait State**: Delay for a specific time or until a timestamp.
*   **Parallel State**: Execute branches concurrently.
*   **Map State**: Iterate over an array of items.

## 🚀 Deployment

### Prerequisites
*   AWS CLI installed and configured.
*   Python 3 installed.

### Steps
1.  **Deploy the Stack**:
    Use CloudFormation to create the IAM roles, Lambda functions, and State Machine.
    ```bash
    aws cloudformation deploy \
      --template-file template.yaml \
      --stack-name sfn-lab-stack \
      --capabilities CAPABILITY_NAMED_IAM
    ```

2.  **Verify Deployment**:
    Check if the stack was created successfully.
    ```bash
    aws cloudformation describe-stacks --stack-name sfn-lab-stack
    ```

## 🧪 Testing

A Python script is provided to trigger the workflow and poll for results.

1.  **Install Dependencies** (if not using the provided venv):
    ```bash
    pip install boto3
    ```

2.  **Run the Test Script**:
    ```bash
    python3 test_workflow.py
    ```

    **Expected Output**:
    *   **Test 1 (Valid Order)**: Should complete with status `SUCCEEDED`.
    *   **Test 2 (Invalid Order)**: Should complete with status `FAILED` (caught by the Catch block).

3.  **Manual Verification**:
    *   Go to the [Step Functions Console](https://console.aws.amazon.com/states).
    *   Click on `OrderProcessingWorkflowCfn`.
    *   View the **Graph Inspector** to see the visual execution path (Green for success, Red for caught errors).

## 🧹 Cleanup

To avoid incurring charges, delete the infrastructure when you are done.

```bash
aws cloudformation delete-stack --stack-name sfn-lab-stack
```
