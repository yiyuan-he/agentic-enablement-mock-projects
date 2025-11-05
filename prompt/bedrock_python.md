# AWS Bedrock Agent Core Runtime - OpenTelemetry Instrumentation Setup Guide

## Overview

A practical guide for enabling OpenTelemetry instrumentation in Python-based AWS Bedrock Agent Core Runtime projects to enhance observability of your AI agents.

## Implementation Steps

### Step 1: Update IAM Execution Role Permissions

Add X-Ray permissions to the Bedrock Agent Core IAM execution role.

#### **Find existing X-Ray permission policy:**
```python
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
```python
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

## Completion

After completing the above three steps, your Python-based AWS Bedrock Agent Core Runtime will automatically enable OpenTelemetry instrumentation, including:

- X-Ray distributed tracing
- AWS Application Signals

---

*Applicable to all Python container-based AWS Bedrock Agent Core Runtime projects*
