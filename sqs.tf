resource "aws_sqs_queue" "ms-queue" {
  name                      = var.sqs_name  
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600  # 4 days
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 0
}

data "aws_sqs_queue" "queue_data" {
  name = aws_sqs_queue.ms-queue.name 
}

output "sqs_queue_name" {
    value = aws_sqs_queue.ms-queue.name
} 

output "sqs_url" {
  value = aws_sqs_queue.ms-queue.url
}