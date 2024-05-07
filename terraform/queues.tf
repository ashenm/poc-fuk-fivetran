locals {
  queues = {
    stagings-mixpanel = {
      bucket_notifications = {
        events        = ["s3:ObjectCreated:*"]
        filter_prefix = "stagings/mixpanel/"
      }
    }
    sources-mixpanel = {
      bucket_notifications = {
        events        = ["s3:ObjectCreated:*"]
        filter_prefix = "sources/mixpanel/"
      }
    }
  }
}

resource "aws_sqs_queue" "main" {
  for_each                   = local.queues
  name                       = upper("${local.name_prefix}-${each.key}")
  visibility_timeout_seconds = 1800
}
