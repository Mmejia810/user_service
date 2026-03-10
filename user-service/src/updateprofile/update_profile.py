import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('TABLE_NAME', 'users-table'))

def lambda_handler(event, context):
    try:
        user_id = event['pathParameters']['user_id']
        documento = event['pathParameters']['documento']
        
        body = json.loads(event['body'])

        # Obtener usuario actual
        response = table.get_item(
            Key={'uuid': user_id, 'documento': documento}
        )

        if 'Item' not in response:
            return {
                "statusCode": 404,
                "body": json.dumps({"error": "Usuario no encontrado"})
            }

        user = response['Item']

        table.update_item(
            Key={'uuid': user_id, 'documento': documento},
            UpdateExpression="set nombre=:n, apellido=:a, #dir=:d, #tel=:p",
            ExpressionAttributeNames={
                "#dir": "dirección",
                "#tel": "teléfono"
            },
            ExpressionAttributeValues={
                ':n': body.get('name', user.get('nombre')),
                ':a': body.get('lastName', user.get('apellido')),
                ':d': body.get('address', user.get('dirección', '')),
                ':p': body.get('phone', user.get('teléfono', ''))
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