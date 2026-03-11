import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
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

        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Perfil actualizado con éxito"})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }