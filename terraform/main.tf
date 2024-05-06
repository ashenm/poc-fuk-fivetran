locals {
  common_tags = {
    Environment = upper(var.environment)
    Project     = upper(var.project)
  }

  name_prefix = upper("${var.environment}-${var.project}")
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
