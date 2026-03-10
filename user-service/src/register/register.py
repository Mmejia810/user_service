import json
import boto3
import uuid
import os
import hashlib

# Configuración de AWS
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
TABLE_NAME = os.environ.get('TABLE_NAME', 'users-table')

def lambda_handler(event, context):
    try:
        # 1. Extraer datos: Maneja Postman (event['body']) y Test manual (event directo)
        if 'body' in event:
            data = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            data = event

        # 2. Validación Crítica: Evita el error "'documento'"
        if 'documento' not in data:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "error": "No llego el campo 'documento'",
                    "recibido": data
                })
            }

        user_uuid = str(uuid.uuid4())
        password = data['contraseña']
        hashed_password = hashlib.sha256(password.encode()).hexdigest()
        table = dynamodb.Table(TABLE_NAME)
        
        # 3. Guardar en DynamoDB
        table.put_item(Item={
            "uuid": user_uuid,
            "documento": str(data['documento']),
            "nombre": data.get('nombre', 'Sin nombre'),
            "apellido": data.get('apellido', 'Sin apellido'),
            "correo electrónico": data.get('correo electrónico', 'Sin correo'),
            "contraseña": hashed_password
        })
        
        return {
            "statusCode": 201,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": "Registro exitoso", "uuid": user_uuid})
        }
        
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error_detectado": str(e)})
        }