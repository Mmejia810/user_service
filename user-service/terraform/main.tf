# terraform/main.tf

provider "aws" {
  region = "us-east-1"
}


# DynamoDB - Tabla Usuarios

resource "aws_dynamodb_table" "users_table" {
  name         = "users-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "uuid"
  range_key    = "documento"

  attribute {
    name = "uuid"
    type = "S"
  }

  attribute {
    name = "documento"
    type = "S"
  }
}


# Secrets Manager - JWT Key

resource "aws_secretsmanager_secret" "jwt_secret" {
  name = "banco-cerdos-jwt-key"
}

resource "aws_secretsmanager_secret_version" "jwt_secret_value" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = "CAMBIA_ESTA_CLAVE_EN_PRODUCCION"
}


# SQS - Cola tarjetas

resource "aws_sqs_queue" "card_request_queue" {
  name = "create-request-card-sqs"
}


# IAM Role para Lambda

resource "aws_iam_role" "lambda_role" {
  name = "user_service_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB Access
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# SQS Access
resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_lambda_function" "register_lambda" {
  filename      = "register.zip"
  function_name = "register-user-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "register.lambda_handler"
  runtime       = "python3.9"
  source_code_hash = filebase64sha256("register.zip")


  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users_table.name
      # Corregido: Ahora coincide con el nombre del recurso definido arriba
      QUEUE_URL  = aws_sqs_queue.card_request_queue.id 
    }
  }
}
# Permiso para que API Gateway pueda ejecutar la Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_lambda.function_name
  principal     = "apigateway.amazonaws.com"


}
# Lambda de Login
resource "aws_lambda_function" "login_lambda" {
  filename      = "login.zip"
  function_name = "login-user-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "login.lambda_handler"
  runtime       = "python3.9"
  source_code_hash = filebase64sha256("login.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users_table.name
      # Usamos el secreto que ya esta creado arriba
      JWT_SECRET = aws_secretsmanager_secret_version.jwt_secret_value.secret_string
    }
  }
}

# Permiso para que API Gateway invoque el Login
resource "aws_lambda_permission" "apigw_login" {
  statement_id  = "AllowAPIGatewayInvokeLogin"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}
# Lambda Get Profile
resource "aws_lambda_function" "get_profile" {
  filename      = "get_profile.zip"
  function_name = "get-profile-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "get_profile.lambda_handler"
  runtime       = "python3.9"
  source_code_hash = filebase64sha256("get_profile.zip")

  environment { variables = { TABLE_NAME = aws_dynamodb_table.users_table.name } }
}

# Lambda Update Profile
resource "aws_lambda_function" "update_profile" {
  filename      = "update_profile.zip"
  function_name = "update-profile-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "update_profile.lambda_handler"
  runtime       = "python3.9"
  source_code_hash = filebase64sha256("update_profile.zip")

  environment { variables = { TABLE_NAME = aws_dynamodb_table.users_table.name } }
}

# Permisos para API Gateway (Añadir para ambas)
resource "aws_lambda_permission" "apigw_get" {
  statement_id  = "AllowGetInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_profile.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "apigw_update" {
  statement_id  = "AllowUpdateInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_profile.function_name
  principal     = "apigateway.amazonaws.com"
}

# S3 Bucket - Avatares de usuarios

resource "aws_s3_bucket" "avatars_bucket" {
  bucket = "users-avatar-banco-cerdos-2026"
}

# S3 Access

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Lambda Upload Avatar

resource "aws_lambda_function" "upload_avatar" {
  filename      = "upload_avatar.zip"
  function_name = "upload-avatar-user-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "upload_avatar.lambda_handler"
  runtime       = "python3.9"
  source_code_hash = filebase64sha256("upload_avatar.zip")

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.users_table.name
      BUCKET_NAME = aws_s3_bucket.avatars_bucket.bucket
    }
  }
}

# Permiso para API Gateway (Avatar)

resource "aws_lambda_permission" "apigw_avatar" {
  statement_id  = "AllowAvatarInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_avatar.function_name
  principal     = "apigateway.amazonaws.com"
}