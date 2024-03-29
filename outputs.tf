output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "ssm_token" {
    value = aws_ssm_parameter.secret_token.name
}

output "ssm_bucket" {
    value = aws_ssm_parameter.S3_bucket.name
}

output "ssm_sqs" {
    value = aws_ssm_parameter.sqs_queue.name
}

output "load_balancer_name" {
  value = local.lb_name
}

output "sqs_queue_name" {
    value = aws_sqs_queue.ms-queue.name
} 

output "sqs_url" {
  value = aws_sqs_queue.ms-queue.url
}

output "s3_bucket_name" {
  value = aws_s3_bucket.final-bucket.bucket
}