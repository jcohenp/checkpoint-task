variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  type    = string
  default = "messages-bucket-checkpoint-assignment"
}

variable "sqs_name" {
  type    = string
  default = "my_sqs"
}

variable "token" {
  type      = string
  sensitive = true
}

variable "node_group1" {
  type      = string
  default = "node-group-1"
}

variable "node_group2" {
  type      = string
  default = "node-group-2"
}

variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "kube-version" {
  type    = string
  default = "36.2.0"
}