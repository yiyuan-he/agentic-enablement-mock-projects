# Enable AWS Application Signals for ECS Services - Complete Implementation Guide

## Overview
This guide provides complete steps to enable AWS Application Signals for ECS Fargate services, distributed tracing, performance monitoring, and service mapping.

## Prerequisites
- Services running on ECS both the ec2 and Fargate launch types.
- Applications using Node.js language

## Implementation Steps

**Constraints:**
You must strictly follow the steps in the order below, do not skip or combine steps.

### Step 1: Add CloudWatch Agent Permissions to ECS Task Role

Update ECS task role to add CloudWatchAgentServerPolicy:

```typescript
// Update existing taskRole or create new one
const taskRole = new iam.Role(this, 'EcsTaskRole', {
  assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
  managedPolicies: [
    iam.ManagedPolicy.fromAwsManagedPolicyName('AWSXRayDaemonWriteAccess'),
    iam.ManagedPolicy.fromAwsManagedPolicyName('CloudWatchAgentServerPolicy'), // Add this policy
  ],
  inlinePolicies: {
    // Your existing inline policies...
  },
});
```

### Step 2: Setup CloudWatch Agent Task
When running in ECS, the CloudWatch Agent is deployed as a sidecar container next to the application container.
Proper permissions, a CWAgentConfig configuration file, and the target log group must be set up to enable logging and metrics collection.

#### 2.1 Create CloudWatch Agent Log Group
```typescript
const cwAgentLogGroup = new logs.LogGroup(this, 'CwAgentLogGroup', {
  logGroupName: '/ecs/ecs-cwagent',
  removalPolicy: cdk.RemovalPolicy.DESTROY,
  retention: logs.RetentionDays.ONE_WEEK,
});
```

#### 2.2 Add CloudWatch Agent Container to Each Task Definition
```typescript
// Add CloudWatch Agent sidecar to each task definition
const cwAgentContainer = taskDefinition.addContainer('ecs-cwagent-{SERVICE_NAME}', {
  image: ecs.ContainerImage.fromRegistry('public.ecr.aws/cloudwatch-agent/cloudwatch-agent:latest'),
  essential: false,
  memoryReservationMiB: 128,
  cpu: 64,
  environment: {
    CW_CONFIG_CONTENT: JSON.stringify({
      "traces": {
        "traces_collected": {
          "application_signals": {}
        }
      },
      "logs": {
        "metrics_collected": {
          "application_signals": {}
        }
      }
    }),
  },
  logging: ecs.LogDrivers.awsLogs({
    streamPrefix: 'ecs',
    logGroup: cwAgentLogGroup,
  }),
});
```

### Step 3: Add ADOT Zero-Code Instrumentation to Main Service

#### 3.1 Add Bind Mount Volumes to Task Definition
```typescript
const taskDefinition = new ecs.FargateTaskDefinition(this, '{SERVICE_NAME}TaskDefinition', {
  // Existing configuration...
  volumes: [
    {
      name: "opentelemetry-auto-instrumentation-node"
    }
  ],
});
```

#### 3.2 Add ADOT Auto-instrumentation Init Container
```typescript
const initContainer = taskDefinition.addContainer('init', {
  image: ecs.ContainerImage.fromRegistry('public.ecr.aws/aws-observability/adot-autoinstrumentation-node:v0.8.0'),
  essential: false,
  memoryReservationMiB: 64,
  cpu: 32,
  command: ['cp', '-a', '/autoinstrumentation/.', '/otel-auto-instrumentation-node'],
  logging: ecs.LogDrivers.awsLogs({
    streamPrefix: 'init-{SERVICE_NAME}',
    logGroup: serviceLogGroup,
  }),
});

// Add mount point to init container
initContainer.addMountPoints({
  sourceVolume: 'opentelemetry-auto-instrumentation-node',
  containerPath: '/otel-auto-instrumentation-node',
  readOnly: false,
});
```

#### 3.3 Configure Main Application Container OpenTelemetry Environment Variables

##### Node.js Application Configuration:
```typescript
const mainContainer = taskDefinition.addContainer('{SERVICE_NAME}-container', {
  // Existing configuration...
  environment: {
    // Existing environment variables...
    
    // ADOT Configuration for Application Signals - Node.js
    OTEL_RESOURCE_ATTRIBUTES: 'service.name={SERVICE_NAME},deployment.environment=ecs-fargate,team.name={TEAM_NAME},business.unit={BUSINESS_UNIT},app={APP_NAME}',
    OTEL_METRICS_EXPORTER: 'none',
    OTEL_LOGS_EXPORTER: 'none',
    NODE_OPTIONS: '--require /otel-auto-instrumentation-node/autoinstrumentation.js',
    OTEL_TRACES_EXPORTER: 'otlp',
    OTEL_EXPORTER_OTLP_PROTOCOL: 'http/protobuf',
    OTEL_EXPORTER_OTLP_TRACES_ENDPOINT: 'http://localhost:4316/v1/traces',
    OTEL_AWS_APPLICATION_SIGNALS_EXPORTER_ENDPOINT: 'http://localhost:4316/v1/metrics',
    OTEL_AWS_APPLICATION_SIGNALS_ENABLED: 'true',
  },
});
```

#### 3.4 Add Mount Point to Main Container
```typescript
// Add mount point to main application container
mainContainer.addMountPoints({
  sourceVolume: 'opentelemetry-auto-instrumentation-node',
  containerPath: '/otel-auto-instrumentation-node',
  readOnly: false,
});
```

#### 3.5 Configure Container Dependencies
```typescript
// Ensure containers start in correct order
mainContainer.addContainerDependencies({
  container: initContainer,
  condition: ecs.ContainerDependencyCondition.SUCCESS,
});

mainContainer.addContainerDependencies({
  container: cwAgentContainer,
  condition: ecs.ContainerDependencyCondition.START,
});
```
