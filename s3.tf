resource "aws_s3_bucket" "final-bucket" {
  bucket = var.bucket_name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.final-bucket.bucket
}