# AWS Bedrock Agent Core Runtime - OpenTelemetry Instrumentation Setup Guide

## Overview

A practical guide for enabling OpenTelemetry instrumentation in Python-based AWS Bedrock Agent Core Runtime projects to enhance observability of your AI agents.

## Implementation Steps

### Step 1: Update IAM Execution Role Permissions

Add X-Ray permissions to the Bedrock Agent Core IAM execution role.

#### **Find existing X-Ray permission policy:**
```typescript
iam.PolicyStatement(
    effect=iam.Effect.ALLOW,
    actions=[
        "xray:PutTelemetryRecords", 
        "xray:GetSamplingRules",
        "xray:GetSamplingTargets"
    ],
    resources=["*"]
)
```

#### **Add `xray:PutTraceSegments` permission:**
```typescript
iam.PolicyStatement(
    effect=iam.Effect.ALLOW,
    actions=[
        "xray:PutTelemetryRecords", 
        "xray:PutTraceSegments",        # ← Add this line
        "xray:GetSamplingRules",
        "xray:GetSamplingTargets"
    ],
    resources=["*"]
)
```

---

### Step 2: Install OpenTelemetry Package in Dockerfile

Install `aws-opentelemetry-distro` when building the Docker image.

#### **Find existing pip install command:**
```dockerfile
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
```

#### **Add OpenTelemetry package installation:**
```dockerfile
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Install AWS OpenTelemetry Distro for observability
RUN pip install --no-cache-dir aws-opentelemetry-distro==0.12.1
```

---

### Step 3: Modify Container Startup Command

Add `opentelemetry-instrument` before the original startup command.

#### **Find existing startup command:**

**CMD format:**
```dockerfile
CMD ["python", "-m", "your_agent"]
```

**ENTRYPOINT format:**
```dockerfile
ENTRYPOINT ["python", "-m", "your_agent"]
```

#### **Modified startup command:**

**CMD format:**
```dockerfile
CMD ["opentelemetry-instrument", "python", "-m", "your_agent"]
```

**ENTRYPOINT format:**
```dockerfile
ENTRYPOINT ["opentelemetry-instrument", "python", "-m", "your_agent"]
```

#### **Common startup command examples:**

```dockerfile
# Basic Python module
CMD ["opentelemetry-instrument", "python", "-m", "basic_agent"]

# Flask application
CMD ["opentelemetry-instrument", "flask", "run", "--host=0.0.0.0"]

# FastAPI application
CMD ["opentelemetry-instrument", "uvicorn", "main:app", "--host=0.0.0.0"]

# Direct Python file execution
CMD ["opentelemetry-instrument", "python", "app.py"]
```

---

### Step 4: Enable CloudWatch OTLP trace endpoint

OpenTelemetry trace data is sent to the CloudWatch OTLP trace endpoint, which requires enabling the Transaction Search feature.

#### **Find existing X-Ray permission policy:**
```typescript
import * as cdk from '@aws-cdk/core';
import * as logs from '@aws-cdk/aws-logs';
import * as xray from '@aws-cdk/aws-xray';

export class XRayTransactionSearchStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Create the resource policy
    const transactionSearchAccess = new logs.CfnResourcePolicy(this, 'XRayLogResourcePolicy', {
      policyName: 'TransactionSearchAccess',
      policyDocument: JSON.stringify({
        Version: '2012-10-17',		 	 	 
        Statement: [
          {
            Sid: 'TransactionSearchXRayAccess',
            Effect: 'Allow',
            Principal: {
              Service: 'xray.amazonaws.com',
            },
            Action: 'logs:PutLogEvents',
            Resource: [
              `arn:${this.partition}:logs:${this.region}:${this.account}:log-group:aws/spans:*`,
              `arn:${this.partition}:logs:${this.region}:${this.account}:log-group:/aws/application-signals/data:*`,
            ],
            Condition: {
              ArnLike: {
                'aws:SourceArn': `arn:${this.partition}:xray:${this.region}:${this.account}:*`,
              },
              StringEquals: {
                'aws:SourceAccount': this.account,
              },
            },
          },
        ],
      }),
    });

    // Create the TransactionSearchConfig with dependency
    const transactionSearchConfig = new xray.CfnTransactionSearchConfig(this, 'XRayTransactionSearchConfig', {
      indexingPercentage: 100,
    });

    // Add the dependency to ensure Resource Policy is created first
    transactionSearchConfig.addDependsOn(transactionSearchAccess);
  }
} 
```


---

## Completion

After completing the above three steps, your Python-based AWS Bedrock Agent Core Runtime will automatically enable OpenTelemetry instrumentation, including:

- X-Ray distributed tracing
- AWS Application Signals

---

*Applicable to all Python container-based AWS Bedrock Agent Core Runtime projects*
