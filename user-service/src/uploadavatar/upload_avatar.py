import json
import os
import boto3
import base64
import uuid
from boto3.dynamodb.conditions import Key

# AWS
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

BUCKET_NAME = os.environ.get('BUCKET_NAME')
TABLE_NAME = os.environ.get('TABLE_NAME')

def lambda_handler(event, context):
    try:

        # Obtener user_id desde la URL
        user_id = event["pathParameters"]["user_id"]

        # Obtener body
        if 'body' in event:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        else:
            body = event

        image_base64 = body["image"]
        file_type = body["fileType"]

        # Decodificar imagen
        image_bytes = base64.b64decode(image_base64)

        # Crear nombre único
        extension = ".jpg"
        if file_type == "image/png":
            extension = ".png"
        elif file_type == "image/jpeg":
            extension = ".jpeg"

        filename = str(uuid.uuid4()) + extension

        # Subir a S3
        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=filename,
            Body=image_bytes,
            ContentType=file_type,
        )

        image_url = f"https://{BUCKET_NAME}.s3.amazonaws.com/{filename}"

        table = dynamodb.Table(TABLE_NAME)

        response = table.query(
            KeyConditionExpression=Key('uuid').eq(user_id)
        )

        items = response.get("Items", [])

        if not items:
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

        documento = items[0]["documento"]

        # Actualizar avatar en DynamoDB
        table.update_item(
          Key={
        "uuid": user_id
         },
         UpdateExpression="SET image = :img",
    ExpressionAttributeValues={
        ":img": image_url
    }
)

        return {
            "statusCode": 200,
             "headers": {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Access-Control-Allow-Methods": "OPTIONS,POST,GET,PUT"
    },
            "body": json.dumps({
                "message": "Avatar subido correctamente",
                "image": image_url
            })
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
            "body": json.dumps({
                "error": str(e)
            })
        }