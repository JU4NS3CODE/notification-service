import json
import uuid
import boto3
import os
from datetime import datetime, timezone

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
notification_table = dynamodb.Table(os.environ['NOTIFICATION_TABLE'])

BUCKET_NAME = os.environ['TEMPLATES_BUCKET']

def get_template(notification_type):
    """Lee la plantilla HTML desde S3"""
    try:
        response = s3.get_object(
            Bucket = BUCKET_NAME,
            Key    = f"{notification_type}.html"
        )
        return response['Body'].read().decode('utf-8')
    except Exception as e:
        print(f"❌ Error leyendo plantilla {notification_type}: {str(e)}")
        raise e

def replace_variables(template, data):
    """Reemplaza variables {{variable}} en la plantilla con los datos reales"""
    for key, value in data.items():
        template = template.replace(f"{{{{{key}}}}}", str(value))
    return template

def lambda_handler(event, context):
    """
    Recibe mensajes de SQS con este formato:
    {
        "type": "WELCOME",
        "data": {
            "fullName": "Jane Doe"
        }
    }
    """
    for record in event['Records']:
        try:
            body              = json.loads(record['body'])
            notification_type = body['type']
            data              = body['data']

            print(f"📧 Procesando notificación tipo: {notification_type}")

            # 1. Leer la plantilla desde S3
            template = get_template(notification_type)

            # 2. Reemplazar variables en la plantilla
            email_content = replace_variables(template, data)

            # 3. Simular envío del correo
            print("=" * 50)
            print(f"📨 ENVIANDO EMAIL")
            print(f"   Tipo:     {notification_type}")
            print(f"   Datos:    {json.dumps(data, indent=2)}")
            print(f"   Contenido:\n{email_content}")
            print("=" * 50)

            # 4. Guardar registro en DynamoDB
            notification_id = str(uuid.uuid4())
            created_at      = datetime.now(timezone.utc).isoformat()

            notification_table.put_item(Item={
                "uuid":      notification_id,
                "type":      notification_type,
                "data":      json.dumps(data),
                "status":    "SENT",
                "createdAt": created_at
            })

            print(f"✅ Notificación guardada: {notification_id}")

        except Exception as e:
            print(f"❌ Error procesando notificación: {str(e)}")
            raise e

    return {"statusCode": 200, "body": "Notificaciones procesadas"}