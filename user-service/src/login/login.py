import json
import os
import boto3
import jwt
import hashlib
import hmac
import datetime
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('TABLE_NAME', 'users-table'))

SECRET_KEY = os.environ.get('JWT_SECRET')
if not SECRET_KEY:
    raise RuntimeError("JWT_SECRET no está configurado en las variables de entorno")


def verificar_password(password: str, stored: str) -> bool:
    try:
        salt, stored_hash = stored.split(':')
        hashed_input = hmac.new(salt.encode(), password.encode('utf-8'), hashlib.sha256).hexdigest()
        return hmac.compare_digest(hashed_input, stored_hash)
    except Exception:
        return False


def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        email = body.get('email')
        password = body.get('password')

        if not email or not password:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "Los campos 'email' y 'password' son obligatorios"})
            }

        response = table.query(
            IndexName='email-index',
            KeyConditionExpression=Key('email').eq(email)
        )

        items = response.get('Items', [])

        if not items:
            return {
                "statusCode": 401,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "Credenciales inválidas"})
            }

        user = items[0]

        if not verificar_password(password, user['password']):
            return {
                "statusCode": 401,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "Credenciales inválidas"})
            }

        now = datetime.datetime.now(datetime.timezone.utc)

        payload = {
            "uuid": user['uuid'],
            "email": user['email'],
            "exp": now + datetime.timedelta(hours=1),
            "iat": now
        }

        token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")

        # 🔔 Enviar notificación USER.LOGIN
        try:
            sqs_client = boto3.client('sqs', region_name='us-east-1')
            sqs_client.send_message(
                QueueUrl=os.environ.get('NOTIFICATION_QUEUE_URL'),
                MessageBody=json.dumps({
                    "type": "USER.LOGIN",
                    "data": {
                        "email": email,
                        "date": now.isoformat()
                    }
                })
            )
        except Exception as notif_error:
            print(f"[ERROR] Notificación USER.LOGIN falló: {notif_error}")

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "message": "Login exitoso",
                "token": token
            })
        }

    except Exception as e:
        import traceback
        print(f"[ERROR] lambda_handler: {e}")
        print(traceback.format_exc())

        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Error interno del servidor"})
        }