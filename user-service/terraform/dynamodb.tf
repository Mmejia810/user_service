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
