# Tabla principal de notificaciones
resource "aws_dynamodb_table" "notification_table" {
  name         = "notification-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "uuid"
  range_key    = "createdAt"

  attribute {
    name = "uuid"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  tags = {
    Name = "notification-table"
  }
}

# Tabla de errores
resource "aws_dynamodb_table" "notification_error_table" {
  name         = "notification-error-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "uuid"
  range_key    = "createdAt"

  attribute {
    name = "uuid"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  tags = {
    Name = "notification-error-table"
  }
}

# Bucket S3 para las plantillas HTML
resource "aws_s3_bucket" "templates_bucket" {
  bucket = "templates-email-notification-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Hacer el bucket privado (las plantillas no deben ser públicas)
resource "aws_s3_bucket_public_access_block" "templates_bucket_private" {
  bucket = aws_s3_bucket.templates_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}