#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { EC2DockerAppStack, DockerAppConfig } from '../lib/docker-stack';
import * as fs from 'fs';
import * as path from 'path';

const app = new cdk.App();

// Use account/region from environment or CLI config
const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION,
};

// Read all config files from config directory
const configDir = path.join(__dirname, '../config');
const configFiles = fs.readdirSync(configDir).filter(f => f.endsWith('.json'));

// Create a stack for each config
configFiles.forEach(configFile => {
  // Validate config file name to prevent path traversal
  if (configFile.includes('..') || configFile.includes('/') || configFile.includes('\\')) {
    throw new Error(`Invalid config file name: ${configFile}`);
  }

  const configPath = path.join(configDir, configFile);
  const config: DockerAppConfig = JSON.parse(fs.readFileSync(configPath, 'utf-8'));

  const stackId = `${config.appName}Stack`;

  new EC2DockerAppStack(app, stackId, config, { env });
});

app.synth();
