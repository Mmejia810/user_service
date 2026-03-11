resource "aws_secretsmanager_secret" "jwt_secret" {
  name = "banco-cerdos-jwt-key"
}

resource "aws_secretsmanager_secret_version" "jwt_secret_value" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = "CAMBIA_ESTA_CLAVE_EN_PRODUCCION"
}
