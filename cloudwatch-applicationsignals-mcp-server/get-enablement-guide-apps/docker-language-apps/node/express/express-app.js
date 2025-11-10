'use strict';

const express = require('express');;
const { S3Client, ListBucketsCommand } = require('@aws-sdk/client-s3');
const logger = require('pino')()

const PORT = parseInt(process.env.SAMPLE_APP_PORT || '8080', 10);
const ADDRESS = process.env.SAMPLE_APP_ADDRESS || 'localhost';

const app = express();

app.get('/', (req, res) => {
  healthCheck(res);
});

app.get('/health', (req, res) => {
  healthCheck(res);
});

function healthCheck(res) {
  logger.info('Health check endpoint called');
  res.type('application/json').send(JSON.stringify({status: 'healthy'}) + '\n');
}

app.get('/api/buckets', async (req, res) => {
  const s3Client = new S3Client({ region: 'us-east-1' });
  try {
    const data = await s3Client.send(new ListBucketsCommand({}));
    const buckets = data.Buckets.map(bucket => bucket.Name);
    logger.info(`Successfully listed ${buckets.length} S3 buckets`);
    res.type('application/json').send(JSON.stringify({
      bucket_count: buckets.length,
      buckets: buckets
    }) + '\n');
  } catch (e) {
    if (e instanceof Error) {
      logger.error(`Exception thrown when Listing Buckets: ${e.message}`);
    }
    res.status(500).type('application/json').send(JSON.stringify({
      error: 'Failed to retrieve S3 buckets'
    }) + '\n');
  }
});

app.listen(PORT, ADDRESS, () => {
  console.log(`Listening for requests on ${ADDRESS}:${PORT}`);
});