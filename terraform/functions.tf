locals {
  functions = {
    mixpanel-canonicalize-events = {
      source      = "functions/mixpanel/canonicalize-events.zip"
      memory_size = 512
      event_source = {
        enabled    = true
        source     = "sources-mixpanel"
        batch_size = 1
      }
    }
    redshift-copy = {
      source      = "functions/redshift/copy.zip"
      memory_size = 512
      environment_variables = {
        common = {
          REDSHIFT_SERVICE_ROLE_ARN   = aws_iam_role.redshift_service_role.arn
          REDSHIFT_CLUSTER_IDENTIFIER = aws_redshift_cluster.main.cluster_identifier
          REDSHIFT_DATABASE           = aws_redshift_cluster.main.database_name
          REDSHIFT_DATABASE_USER      = aws_redshift_cluster.main.master_username
        }
      }
      event_source = {
        enabled    = true
        source     = "stagings-mixpanel"
        batch_size = 1
      }
    }
  }
}

resource "aws_lambda_function" "main" {
  for_each         = local.functions
  function_name    = upper("${local.name_prefix}-${each.key}")
  filename         = "${path.root}/../dist/${each.value.source}"
  source_code_hash = filebase64sha256("${path.root}/../dist/${each.value.source}")
  handler          = "index.handler"
  role             = aws_iam_role.functions[each.key].arn
  runtime          = lookup(each.value, "runtime", "nodejs20.x")
  memory_size      = lookup(each.value, "memory_size", 128)
  timeout          = lookup(each.value, "timeout", 300)

  environment {
    variables = merge({
      ENVIRONMENT = var.environment
    }, try(each.value.environment_variables.common, {}), try(each.value.environment_variables[lower(var.environment)], {}))
  }

  ephemeral_storage {
    size = lookup(each.value, "ephemeral_storage", 512)
  }
}
