resource "aws_sqs_queue" "card_request_queue" {
  name = "create-request-card-sqs"
}