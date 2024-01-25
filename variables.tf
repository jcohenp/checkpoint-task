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