# ============================================
# EMPAQUETAR EL CÓDIGO PYTHON EN ZIPS
# ============================================

data "archive_file" "send_notifications_zip" {
  type        = "zip"
  source_file = "../src/send_notifications/handler.py"
  output_path = "../src/zips/send_notifications.zip"
}

data "archive_file" "send_notifications_error_zip" {
  type        = "zip"
  source_file = "../src/send_notifications_error/handler.py"
  output_path = "../src/zips/send_notifications_error.zip"
}

# ============================================
# CREAR LAS LAMBDAS EN AWS
# ============================================

# Lambda principal - escucha SQS y envía notificaciones
resource "aws_lambda_function" "send_notifications" {
  filename         = data.archive_file.send_notifications_zip.output_path
  function_name    = "send-notifications-lambda"
  role             = aws_iam_role.notification_lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  source_code_hash = data.archive_file.send_notifications_zip.output_base64sha256

  environment {
    variables = {
      TEMPLATES_BUCKET   = aws_s3_bucket.templates_bucket.bucket
      NOTIFICATION_TABLE = "notification-table"
    }
  }
}

# Lambda de errores - escucha la DLQ
resource "aws_lambda_function" "send_notifications_error" {
  filename         = data.archive_file.send_notifications_error_zip.output_path
  function_name    = "send-notifications-error-lambda"
  role             = aws_iam_role.notification_lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 15
  source_code_hash = data.archive_file.send_notifications_error_zip.output_base64sha256

  environment {
    variables = {
      NOTIFICATION_ERROR_TABLE = "notification-error-table"
    }
  }
}

# ============================================
# CONECTAR LAS COLAS SQS CON LAS LAMBDAS
# ============================================

# Cola principal → send_notifications
resource "aws_lambda_event_source_mapping" "sqs_to_notifications" {
  event_source_arn = aws_sqs_queue.notification_queue.arn
  function_name    = aws_lambda_function.send_notifications.arn
  batch_size       = 5
  enabled          = true
}

# DLQ → send_notifications_error
resource "aws_lambda_event_source_mapping" "dlq_to_notifications_error" {
  event_source_arn = aws_sqs_queue.notification_dlq.arn
  function_name    = aws_lambda_function.send_notifications_error.arn
  batch_size       = 5
  enabled          = true
}

# ============================================
# SUBIR LAS PLANTILLAS HTML A S3
# ============================================

resource "aws_s3_object" "template_welcome" {
  bucket       = aws_s3_bucket.templates_bucket.bucket
  key          = "WELCOME.html"
  source       = "../templates/WELCOME.html"
  content_type = "text/html"
}

resource "aws_s3_object" "template_user_login" {
  bucket       = aws_s3_bucket.templates_bucket.bucket
  key          = "USER.LOGIN.html"
  source       = "../templates/USER.LOGIN.html"
  content_type = "text/html"
}

resource "aws_s3_object" "template_user_update" {
  bucket       = aws_s3_bucket.templates_bucket.bucket
  key          = "USER.UPDATE.html"
  source       = "../templates/USER.UPDATE.html"
  content_type = "text/html"
}

resource "aws_s3_object" "template_card_create" {
  bucket       = aws_s3_bucket.templates_bucket.bucket
  key          = "CARD.CREATE.html"
  source       = "../templates/CARD.CREATE.html"
  content_type = "text/html"
}

resource "aws_s3_object" "template_card_activate" {
  bucket       = aws_s3_bucket.templates_bucket.bucket
  key          = "CARD.ACTIVATE.html"
  source       = "../templates/CARD.ACTIVATE.html"
  content_type = "text/html"
}

resource "aws_s3_object" "template_transaction_purchase" {
  bucket       = aws_s3_bucket.templates_bucket.bucket
  key          = "TRANSACTION.PURCHASE.html"
  source       = "../templates/TRANSACTION.PURCHASE.html"
  content_type = "text/html"
}

resource "aws_s3_object" "template_transaction_save" {
  bucket       = aws_s3_bucket.templates_bucket.bucket
  key          = "TRANSACTION.SAVE.html"
  source       = "../templates/TRANSACTION.SAVE.html"
  content_type = "text/html"
}

resource "aws_s3_object" "template_transaction_paid" {
  bucket       = aws_s3_bucket.templates_bucket.bucket
  key          = "TRANSACTION.PAID.html"
  source       = "../templates/TRANSACTION.PAID.html"
  content_type = "text/html"
}

resource "aws_s3_object" "template_report_activity" {
  bucket       = aws_s3_bucket.templates_bucket.bucket
  key          = "REPORT.ACTIVITY.html"
  source       = "../templates/REPORT.ACTIVITY.html"
  content_type = "text/html"
}

# ============================================
# OUTPUTS
# ============================================

output "notification_queue_url" {
  value       = aws_sqs_queue.notification_queue.url
  description = "URL de la cola SQS de notificaciones"
}

output "templates_bucket_name" {
  value       = aws_s3_bucket.templates_bucket.bucket
  description = "Nombre del bucket S3 con las plantillas"
}
