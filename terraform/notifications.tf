resource "aws_s3_bucket_notification" "main" {
  bucket = aws_s3_bucket.main.id

  dynamic "queue" {
    for_each = { for k, v in local.queues : k => v if can(v.bucket_notifications) }

    content {
      id            = queue.key
      queue_arn     = aws_sqs_queue.main[queue.key].arn
      events        = queue.value.bucket_notifications.events
      filter_prefix = lookup(queue.value.bucket_notifications, "filter_prefix", null)
      filter_suffix = lookup(queue.value.bucket_notifications, "ffilter_suffix", null)
    }
  }

  depends_on = [aws_sqs_queue_policy.bucket_notifications]
}

resource "aws_lambda_event_source_mapping" "queues" {
  for_each         = { for k, v in local.functions : k => v if can(v.event_source) }
  event_source_arn = aws_sqs_queue.main[each.value.event_source.source].arn
  function_name    = aws_lambda_function.main[each.key].arn
}

resource "aws_sqs_queue_policy" "bucket_notifications" {
  for_each  = { for k, v in local.queues : k => v if can(v.bucket_notifications) }
  queue_url = aws_sqs_queue.main[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sqs:SendMessage"
        Effect = "Allow"
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.main.arn
          }
        }
        Resource  = "*"
        Principal = "*"
      }
    ]
  })
}
