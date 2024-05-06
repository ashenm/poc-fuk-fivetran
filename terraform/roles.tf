resource "aws_iam_role" "functions" {
  for_each = local.functions
  name     = upper("${local.name_prefix}-${each.key}")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name   = "VPCAccessExecutionRole"
    policy = data.aws_iam_policy.lambdas.policy
  }
}

resource "aws_iam_role" "redshift_service_role" {
  name = upper("${local.name_prefix}-redshift-service-role")

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow",
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "SourceReadOnlyAccess"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:Get*",
            "s3:List*",
            "s3:Describe*",
            "s3-object-lambda:Get*",
            "s3-object-lambda:List*"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = "kms:Decrypt"
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  inline_policy {
    name = "DestinationReadWriteAccess"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "RedshiftDataAPIPermissions",
          Effect = "Allow",
          Action = [
            "redshift-data:ExecuteStatement",
            "redshift-data:GetStatementResult",
            "redshift-data:DescribeStatement"
          ],
          Resource = "*"
        },
        {
          Sid    = "RedshiftAPIUserCredentialsPermissions",
          Effect = "Allow",
          Action = "redshift:GetClusterCredentials",
          Resource = [
            "arn:${data.aws_partition.current.partition}:redshift:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbname:${lower(local.name_prefix)}/workbench",
            "arn:${data.aws_partition.current.partition}:redshift:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${lower(local.name_prefix)}/master",
          ]
        },
        {
          Sid      = "RedshiftServerlessCredentialsPermissions",
          Effect   = "Allow",
          Action   = "redshift-serverless:GetCredentials",
          Resource = "*"
        },
        {
          Sid      = "IAMServiceLinkedRolePermissions",
          Effect   = "Allow",
          Action   = "iam:CreateServiceLinkedRole",
          Resource = "arn:${data.aws_partition.current.partition}:iam::*:role/aws-service-role/redshift-data.amazonaws.com/AWSServiceRoleForRedshift",
          Condition = {
            StringLike = {
              "iam:AWSServiceName" : "redshift-data.amazonaws.com"
            }
          }
        }
      ]
    })
  }
}
