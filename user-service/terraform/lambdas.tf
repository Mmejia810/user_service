# Lambda Register
resource "aws_lambda_function" "register_lambda" {
  filename         = "${path.module}/register.zip"
  function_name    = "register-user-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "register.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/register.zip")

  environment {
    variables = {
      TABLE_NAME             = aws_dynamodb_table.users_table.name
      QUEUE_URL              = aws_sqs_queue.card_request_queue.id
      NOTIFICATION_QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/825982958931/notification-email-sqs" # ← AGREGAR
    }
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

# Lambda Login
resource "aws_lambda_function" "login_lambda" {
  filename         = "${path.module}/login.zip"
  function_name    = "login-user-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "login.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/login.zip")

    environment {
    variables = {
      TABLE_NAME             = aws_dynamodb_table.users_table.name
      JWT_SECRET             = aws_secretsmanager_secret_version.jwt_secret_value.secret_string
      NOTIFICATION_QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/825982958931/notification-email-sqs"  # ← AGREGAR
    }
  }
}

resource "aws_lambda_permission" "apigw_login" {
  statement_id  = "AllowAPIGatewayInvokeLogin"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

# Lambda Get Profile
resource "aws_lambda_function" "get_profile" {
  filename         = "${path.module}/get_profile.zip"
  function_name    = "get-profile-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "get_profile.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/get_profile.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users_table.name
    }
  }
}

resource "aws_lambda_permission" "apigw_get" {
  statement_id  = "AllowGetInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_profile.function_name
  principal     = "apigateway.amazonaws.com"
}

# Lambda Update Profile
resource "aws_lambda_function" "update_profile" {
  filename         = "${path.module}/update_profile.zip"
  function_name    = "update-profile-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "update_profile.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/update_profile.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users_table.name
    }
  }
}

resource "aws_lambda_permission" "apigw_update" {
  statement_id  = "AllowUpdateInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_profile.function_name
  principal     = "apigateway.amazonaws.com"
}

# Lambda Upload Avatar
resource "aws_lambda_function" "upload_avatar" {
  filename         = "${path.module}/upload_avatar.zip"
  function_name    = "upload-avatar-user-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "upload_avatar.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/upload_avatar.zip")

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.users_table.name
      BUCKET_NAME = aws_s3_bucket.avatars_bucket.bucket
    }
  }
}

resource "aws_lambda_permission" "apigw_avatar" {
  statement_id  = "AllowAvatarInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_avatar.function_name
  principal     = "apigateway.amazonaws.com"
}
