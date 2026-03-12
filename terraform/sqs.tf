# DLQ - Cola de errores
resource "aws_sqs_queue" "notification_dlq" {
  name                      = "notification-email-error-sqs"
  message_retention_seconds = 1209600
}

# Cola principal de notificaciones
resource "aws_sqs_queue" "notification_queue" {
  name                       = "notification-email-sqs"
  visibility_timeout_seconds = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_dlq.arn
    maxReceiveCount     = 3
  })
}