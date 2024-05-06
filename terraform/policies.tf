resource "aws_iam_policy" "function_mixpanel_canonicalize_events" {
  name = upper("${local.name_prefix}-mixpanel-canonicalize-events")
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage"
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.main["sources-mixpanel"].arn
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.main.arn}/sources",
          "${aws_s3_bucket.main.arn}/sources/*"
        ]
      },
      {
        Action = [
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.main.arn}/stagings/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "function_mixpanel_canonicalize_events" {
  policy_arn = aws_iam_policy.function_mixpanel_canonicalize_events.arn
  role       = aws_iam_role.functions["mixpanel-canonicalize-events"].name
}

resource "aws_iam_policy" "function_redshift_copy" {
  name = upper("${local.name_prefix}-redshift-copy")
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage"
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.main["stagings-mixpanel"].arn
      },
      {
        Sid = "RedshiftDataAPIPermissions",
        Action = [
          "redshift-data:DescribeStatement",
          "redshift-data:ExecuteStatement",
          "redshift-data:GetStatementResult"
        ]
        Effect   = "Allow"
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
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "function_redshift_copy" {
  policy_arn = aws_iam_policy.function_redshift_copy.arn
  role       = aws_iam_role.functions["redshift-copy"].name
}

data "aws_iam_policy" "lambdas" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
