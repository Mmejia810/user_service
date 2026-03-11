import json
import boto3
import uuid
import os
import re
import hashlib
import hmac
import secrets
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
sqs = boto3.client('sqs', region_name='us-east-1')

TABLE_NAME = os.environ.get('TABLE_NAME', 'users-table')

QUEUE_URL = os.environ.get('QUEUE_URL')
if not QUEUE_URL:
    raise RuntimeError("QUEUE_URL no está configurado en las variables de entorno")


def validar_email(email: str) -> bool:
    return bool(re.match(r'^[\w\.-]+@[\w\.-]+\.\w+$', email))


def validar_password(password: str) -> bool:
    return len(password) >= 8


def hashear_password(password: str) -> str:
    # Genera un salt aleatorio y lo combina con la contraseña
    salt = secrets.token_hex(32)
    hashed = hmac.new(salt.encode(), password.encode('utf-8'), hashlib.sha256).hexdigest()
    return f"{salt}:{hashed}"  # Se guarda salt:hash juntos en DynamoDB


def lambda_handler(event, context):
    try:
        if 'body' in event:
            data = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            data = event

        campos_requeridos = ['documento', 'nombre', 'apellido', 'email', 'password']
        for campo in campos_requeridos:
            if campo not in data:
                return {
                    "statusCode": 400,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"error": f"Falta el campo obligatorio: '{campo}'"})
                }

        if not validar_email(data['email']):
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "El formato del email es inválido"})
            }

        if not validar_password(data['password']):
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "La contraseña debe tener mínimo 8 caracteres"})
            }

        table = dynamodb.Table(TABLE_NAME)

        existing = table.query(
            IndexName='email-index',
            KeyConditionExpression=Key('email').eq(data['email'])
        )
        if existing.get('Items'):
            return {
                "statusCode": 409,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "El correo ya está registrado"})
            }

        # Hashear con hmac + salt 
        hashed_password = hashear_password(data['password'])

        user_uuid = str(uuid.uuid4())

        table.put_item(Item={
            "uuid": user_uuid,
            "documento": str(data['documento']),
            "nombre": data['nombre'],
            "apellido": data['apellido'],
            "email": data['email'],
            "password": hashed_password
        })

        sqs_errors = []
        for request_type in ["DEBIT", "CREDIT"]:
            try:
                sqs.send_message(
                    QueueUrl=QUEUE_URL,
                    MessageBody=json.dumps({
                        "userId": user_uuid,
                        "request": request_type
                    })
                )
            except Exception as sqs_error:
                sqs_errors.append(f"{request_type}: {str(sqs_error)}")
                print(f"[ERROR] SQS {request_type} falló para usuario {user_uuid}: {sqs_error}")

        response_body = {"message": "Registro exitoso", "uuid": user_uuid}
        if sqs_errors:
            response_body["sqs_warnings"] = sqs_errors

        return {
            "statusCode": 201,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(response_body)
        }

    except Exception as e:
     import traceback
     print(f"[ERROR] lambda_handler: {e}")
     print(traceback.format_exc())  # ← Agrega esto
     return {
        "statusCode": 500,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"error": "Error interno del servidor"})
    }