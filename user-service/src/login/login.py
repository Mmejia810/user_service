import json
import os
import boto3
import jwt
import datetime
import hashlib
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users-table')

SECRET_KEY = os.environ.get('JWT_SECRET', 'clave-de-emergencia')

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        email = body['correo electrónico']
        password = body['contraseña']

        # Buscar usuario en DynamoDB
        response = table.scan(
            FilterExpression=Attr('correo electrónico').eq(email)
        )

        items = response.get('Items', [])

        if not items:
            return {
                "statusCode": 401,
                "body": json.dumps({"error": "Usuario no encontrado"})
            }

        user = items[0]

        # Hashear la contraseña ingresada
        hashed_input = hashlib.sha256(password.encode()).hexdigest()

        # Comparar hash
        if user['contraseña'] != hashed_input:
            return {
                "statusCode": 401,
                "body": json.dumps({"error": "Contraseña incorrecta"})
            }

        # Generar JWT
        payload = {
            "uuid": user['uuid'],
            "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1),
            "iat": datetime.datetime.utcnow()
        }

        token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Login exitoso",
                "token": token
            })
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }