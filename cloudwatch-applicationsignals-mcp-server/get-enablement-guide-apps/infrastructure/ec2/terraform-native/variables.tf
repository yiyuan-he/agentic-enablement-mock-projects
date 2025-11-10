variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "language" {
  description = "Programming language of the application (python, nodejs, java)"
  type        = string

  validation {
    condition     = contains(["python", "nodejs", "java"], var.language)
    error_message = "Language must be one of: python, nodejs, java"
  }
}

variable "port" {
  description = "Port the application runs on"
  type        = number
}

variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = "/health"
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "app_source_path" {
  description = "Path to the application source code directory"
  type        = string
}

variable "service_name" {
  description = "Name of the systemd service"
  type        = string
}
