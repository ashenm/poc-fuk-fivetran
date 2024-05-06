resource "aws_s3_bucket" "main" {
  bucket        = lower(local.name_prefix)
  force_destroy = lower(var.environment) != "production"
}
