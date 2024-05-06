variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "environment" {
  type    = string
  default = "development"

  validation {
    condition     = can(regex("^(?:development|staging|production)$", var.environment))
    error_message = "environment must be one of development, staging, or production"
  }
}

variable "project" {
  type    = string
  default = "fuk-fivetran"
}
