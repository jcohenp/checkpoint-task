resource "aws_ssm_parameter" "secret_token" {
  name        = "token-ms-1"
  description = "token to check before send to sqs"
  type        = "SecureString"
  value       = var.token
  overwrite   = true
  
  tags = {
    Terraform = "true"
    Environment = "checkpoint"
  }
}

resource "aws_ssm_parameter" "sqs_queue" {
  name        = var.sqs_name
  description = "sqs queue to use to send message then to push on s3 bucket"
  type        = "String"
  value       = aws_sqs_queue.ms-queue.url

  tags = {
    Terraform = "true"
    Environment = "checkpoint"
  }
}

resource "aws_ssm_parameter" "S3_bucket" {
  name        = "S3_bucket"
  description = "Name of the bucket to push the message from sqs"
  type        = "String"
  value       = var.bucket_name

  tags = {
    Terraform = "true"
    Environment = "checkpoint"
  }
}

resource "aws_ssm_parameter" "eks_cluster_name" {
  name        = "eks_cluster_name"
  description = "name of the eks cluster"
  type        = "String"
  value       = local.cluster_name

  tags = {
    Terraform = "true"
    Environment = "checkpoint"
  }
}

resource "aws_ssm_parameter" "processing_requests_externalIP" {
  name        = "processing_requests_externalIP"
  description = "name of the external IP to talk with the processing requests ms"
  type        = "String"
  value       = local.lb_name

  tags = {
    Terraform = "true"
    Environment = "checkpoint"
  }
}