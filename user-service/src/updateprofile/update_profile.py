import json
import boto3
import os
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs', region_name='us-east-1')
table = dynamodb.Table(os.environ.get('TABLE_NAME', 'users-table'))

def lambda_handler(event, context):
    try:
        user_id = event['pathParameters']['user_id']
        body = json.loads(event['body'])

        # Obtener usuario actual
        response = table.get_item(
            Key={'uuid': user_id}
        )

        if 'Item' not in response:
            return {
                "statusCode": 404,
                 "headers": {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Access-Control-Allow-Methods": "OPTIONS,POST,GET,PUT"
    },
                "body": json.dumps({"error": "Usuario no encontrado"})
            }

        user = response['Item']

        table.update_item(
            Key={'uuid': user_id},
            UpdateExpression="SET nombre=:n, apellido=:a, direccion=:d, telefono=:p",
            ExpressionAttributeValues={
                ':n': body.get('name', user.get('nombre')),
                ':a': body.get('lastName', user.get('apellido')),
                ':d': body.get('direccion', user.get('direccion', '')),
                ':p': body.get('telefono', user.get('telefono', ''))
            }
        )

        # Enviar notificación USER.UPDATE
        try:
            sqs.send_message(
                QueueUrl=os.environ.get('NOTIFICATION_QUEUE_URL'),
                MessageBody=json.dumps({
                    "type": "USER.UPDATE",
                    "data": {
                        "date": datetime.now(timezone.utc).isoformat()
                    }
                })
            )
        except Exception as notif_error:
            print(f"[ERROR] Notificación USER.UPDATE falló: {notif_error}")

        return {
            "statusCode": 200,
             "headers": {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Access-Control-Allow-Methods": "OPTIONS,POST,GET,PUT"
    },
            "body": json.dumps({"message": "Perfil actualizado con éxito"})
        }

    except Exception as e:
        return {
            "statusCode": 500,
             "headers": {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Access-Control-Allow-Methods": "OPTIONS,POST,GET,PUT"
    },
            "body": json.dumps({"error": str(e)})
        }