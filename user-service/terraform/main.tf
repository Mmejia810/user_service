provider "aws" {
  region = "us-east-1"

  endpoints {
    dynamodb       = "https://dynamodb.us-east-1.amazonaws.com"
    sqs            = "https://sqs.us-east-1.amazonaws.com"
    iam            = "https://iam.amazonaws.com"
    secretsmanager = "https://secretsmanager.us-east-1.amazonaws.com"
  }
}