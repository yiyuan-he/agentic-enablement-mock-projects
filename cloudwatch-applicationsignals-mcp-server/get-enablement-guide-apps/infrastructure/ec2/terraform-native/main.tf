terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "archive_file" "app_code" {
  type        = "zip"
  source_dir  = var.app_source_path
  output_path = "${path.module}/app-${var.app_name}.zip"
}

resource "aws_s3_bucket" "app_code" {
  bucket_prefix = "${lower(var.app_name)}-code-"
  force_destroy = true
}

resource "aws_s3_object" "app_code" {
  bucket = aws_s3_bucket.app_code.id
  key    = "app.zip"
  source = data.archive_file.app_code.output_path
  etag   = data.archive_file.app_code.output_md5
}

resource "aws_iam_role" "app_role" {
  name = "${var.app_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_readonly" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "${var.app_name}-profile"
  role = aws_iam_role.app_role.name
}

resource "aws_security_group" "app_sg" {
  name        = "${var.app_name}-sg"
  description = "Security group for ${var.app_name}"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-sg"
  }
}

locals {
  install_commands = {
    python = "yum install -y python3 python3-pip unzip"
    nodejs = "yum install -y nodejs npm unzip"
    java   = "yum install -y java-17-amazon-corretto maven unzip"
  }

  dep_install_commands = {
    python = "cd /opt/app && pip3 install -r requirements.txt"
    nodejs = "cd /opt/app && npm install --production"
    java   = "cd /opt/app && mvn clean package -DskipTests"
  }

  start_commands = {
    python = "/usr/bin/python3 /opt/app/app.py"
    nodejs = "/usr/bin/node /opt/app/express-app.js"
    java   = "/usr/bin/java -jar /opt/app/target/*.jar"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e

              yum update -y
              ${lookup(local.install_commands, var.language, "yum install -y unzip")}

              mkdir -p /opt/app
              aws s3 cp s3://${aws_s3_bucket.app_code.id}/${aws_s3_object.app_code.key} /tmp/app.zip
              cd /opt/app
              unzip /tmp/app.zip
              chown -R ec2-user:ec2-user /opt/app

              ${lookup(local.dep_install_commands, var.language, "")}

              cat > /etc/systemd/system/${var.service_name}.service << 'EOFSERVICE'
              [Unit]
              Description=${var.app_name}
              After=network.target

              [Service]
              Type=simple
              User=ec2-user
              WorkingDirectory=/opt/app
              Environment="PORT=${var.port}"
              Environment="AWS_REGION=${var.aws_region}"
              ExecStart=${lookup(local.start_commands, var.language, "")}
              Restart=always
              RestartSec=10

              [Install]
              WantedBy=multi-user.target
              EOFSERVICE

              systemctl daemon-reload
              systemctl enable ${var.service_name}
              systemctl start ${var.service_name}

              sleep 10

              sudo -u ec2-user bash /opt/app/generate-traffic.sh &

              echo "Application deployed and traffic generation started"
              EOF
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.small"
  iam_instance_profile   = aws_iam_instance_profile.app_profile.name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = local.user_data

  tags = {
    Name     = var.app_name
    Language = var.language
  }

  depends_on = [aws_s3_object.app_code]
}
