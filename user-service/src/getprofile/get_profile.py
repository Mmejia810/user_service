import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('TABLE_NAME', 'users-table')
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    try:
        user_id = event['pathParameters']['user_id']
        documento = event['pathParameters']['documento']

        response = table.get_item(
            Key={
                'uuid': user_id,
                'documento': documento
            }
        )

        if 'Item' not in response:
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "Usuario no encontrado"})
            }

        user = response['Item']

        # Imagen (si no existe usa placeholder)
        image = user.get('image')
        if not image:
            image = "https://via.placeholder.com/150"

        result = {
            "name": user.get('nombre'),
            "lastName": user.get('apellido'),
            "email": user.get('correo electrónico'),
            "documento": user.get('documento'),
            "direccion": user.get('dirección', ""),
            "telefono": user.get('teléfono', ""),
            "image": image
        }

        return {
            "statusCode": 200,
            "body": json.dumps(result)
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }