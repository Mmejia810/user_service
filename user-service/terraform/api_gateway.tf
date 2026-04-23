resource "aws_api_gateway_rest_api" "user_api" {
  name        = "user-service-api"
  description = "API para el servicio de usuarios"
}

# /users
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  parent_id   = aws_api_gateway_rest_api.user_api.root_resource_id
  path_part   = "users"
}

# /users/register
resource "aws_api_gateway_resource" "register" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "register"
}

resource "aws_api_gateway_method" "post_register" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.register.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "register_integration" {
  rest_api_id             = aws_api_gateway_rest_api.user_api.id
  resource_id             = aws_api_gateway_resource.register.id
  http_method             = aws_api_gateway_method.post_register.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.register_lambda.invoke_arn
}

# /users/login
resource "aws_api_gateway_resource" "login" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "login"
}

resource "aws_api_gateway_method" "post_login" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.login.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "login_integration" {
  rest_api_id             = aws_api_gateway_rest_api.user_api.id
  resource_id             = aws_api_gateway_resource.login.id
  http_method             = aws_api_gateway_method.post_login.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.login_lambda.invoke_arn
}

# /profile
resource "aws_api_gateway_resource" "profile" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  parent_id   = aws_api_gateway_rest_api.user_api.root_resource_id
  path_part   = "profile"
}

# /profile/{user_id}
resource "aws_api_gateway_resource" "profile_user_id" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  parent_id   = aws_api_gateway_resource.profile.id
  path_part   = "{user_id}"
}

resource "aws_api_gateway_method" "get_profile" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.profile_user_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_profile_integration" {
  rest_api_id             = aws_api_gateway_rest_api.user_api.id
  resource_id             = aws_api_gateway_resource.profile_user_id.id
  http_method             = aws_api_gateway_method.get_profile.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_profile.invoke_arn
}

resource "aws_api_gateway_method" "put_profile" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.profile_user_id.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "update_profile_integration" {
  rest_api_id             = aws_api_gateway_rest_api.user_api.id
  resource_id             = aws_api_gateway_resource.profile_user_id.id
  http_method             = aws_api_gateway_method.put_profile.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.update_profile.invoke_arn
}

# /profile/{user_id}/avatar
resource "aws_api_gateway_resource" "avatar" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  parent_id   = aws_api_gateway_resource.profile_user_id.id
  path_part   = "avatar"
}

resource "aws_api_gateway_method" "post_avatar" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.avatar.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "avatar_integration" {
  rest_api_id             = aws_api_gateway_rest_api.user_api.id
  resource_id             = aws_api_gateway_resource.avatar.id
  http_method             = aws_api_gateway_method.post_avatar.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.upload_avatar.invoke_arn
}

# DEPLOY
resource "aws_api_gateway_deployment" "user_deploy" {
  depends_on = [
    aws_api_gateway_integration.register_integration,
    aws_api_gateway_integration.login_integration,
    aws_api_gateway_integration.get_profile_integration,
    aws_api_gateway_integration.update_profile_integration,
    aws_api_gateway_integration.avatar_integration,
    aws_api_gateway_integration_response.options_register,
    aws_api_gateway_integration_response.options_login,
    aws_api_gateway_integration_response.options_profile,
aws_api_gateway_integration_response.options_avatar,
  ]
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "user_stage" {
  deployment_id = aws_api_gateway_deployment.user_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  stage_name    = "dev"
}

output "user_api_url" {
  value = aws_api_gateway_stage.user_stage.invoke_url
}


# ── CORS: /users/register ──
resource "aws_api_gateway_method" "options_register" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.register.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_register" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.register.id
  http_method = aws_api_gateway_method.options_register.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_register" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.register.id
  http_method = aws_api_gateway_method.options_register.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_register" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.register.id
  http_method = aws_api_gateway_method.options_register.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_register]
}

# ── CORS: /users/login ──
resource "aws_api_gateway_method" "options_login" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.login.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_login" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.login.id
  http_method = aws_api_gateway_method.options_login.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_login" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.login.id
  http_method = aws_api_gateway_method.options_login.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_login" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.login.id
  http_method = aws_api_gateway_method.options_login.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_login]
}

resource "aws_api_gateway_method" "options_profile" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.profile_user_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_profile" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.profile_user_id.id
  http_method = aws_api_gateway_method.options_profile.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_profile" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.profile_user_id.id
  http_method = aws_api_gateway_method.options_profile.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_profile" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.profile_user_id.id
  http_method = aws_api_gateway_method.options_profile.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_profile]
}

resource "aws_api_gateway_method" "options_avatar" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.avatar.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_avatar" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.avatar.id
  http_method = aws_api_gateway_method.options_avatar.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_avatar" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.avatar.id
  http_method = aws_api_gateway_method.options_avatar.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_avatar" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.avatar.id
  http_method = aws_api_gateway_method.options_avatar.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_avatar]
}