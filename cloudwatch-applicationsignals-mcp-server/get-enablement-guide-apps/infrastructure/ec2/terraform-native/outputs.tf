output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.app.id
}

output "instance_public_ip" {
  description = "EC2 Instance Public IP"
  value       = aws_instance.app.public_ip
}

output "health_check_url" {
  description = "Health check endpoint URL"
  value       = "http://${aws_instance.app.public_ip}:${var.port}${var.health_check_path}"
}

output "buckets_api_url" {
  description = "Buckets API endpoint URL"
  value       = "http://${aws_instance.app.public_ip}:${var.port}/api/buckets"
}

output "service_name" {
  description = "Systemd service name"
  value       = var.service_name
}

output "language" {
  description = "Application language"
  value       = var.language
}

output "s3_bucket_name" {
  description = "S3 bucket containing application code"
  value       = aws_s3_bucket.app_code.id
}

output "s3_object_key" {
  description = "S3 object key for application code"
  value       = aws_s3_object.app_code.key
}
