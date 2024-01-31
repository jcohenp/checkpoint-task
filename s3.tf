resource "aws_s3_bucket" "final-bucket" {
  bucket = var.bucket_name
}