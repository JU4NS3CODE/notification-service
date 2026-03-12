import json
import uuid
import boto3
import os
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb')
error_table = dynamodb.Table(os.environ['NOTIFICATION_ERROR_TABLE'])

def lambda_handler(event, context):
    """
    Recibe mensajes que fallaron 3 veces en la cola principal
    Los guarda en notification-error-table para auditoría
    """
    for record in event['Records']:
        try:
            error_id   = str(uuid.uuid4())
            created_at = datetime.now(timezone.utc).isoformat()

            # Intentar parsear el mensaje original
            try:
                original_body = json.loads(record['body'])
                notification_type = original_body.get('type', 'UNKNOWN')
            except:
                notification_type = 'UNKNOWN'

            error_item = {
                "uuid":            error_id,
                "type":            notification_type,
                "originalMessage": record['body'],
                "errorSource":     "notification-email-sqs",
                "status":          "FAILED",
                "createdAt":       created_at
            }

            error_table.put_item(Item=error_item)
            print(f"⚠️ Error guardado en auditoría: {error_id} | Tipo: {notification_type}")

        except Exception as e:
            print(f"❌ Error guardando en tabla de errores: {str(e)}")
            raise e

    return {"statusCode": 200}
