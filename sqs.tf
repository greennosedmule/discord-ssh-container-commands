resource "aws_sqs_queue" "discord_requests" {
  name                       = "${var.resource_prefix}Discord-Requests"
  visibility_timeout_seconds = 120 # needs to match lambda trigger
}


resource "aws_lambda_event_source_mapping" "sqs_requests_to_lambda_responder" {
  enabled          = true
  event_source_arn = aws_sqs_queue.discord_requests.arn
  function_name    = aws_lambda_function.discord_responder.arn
  batch_size       = 1
}


resource "aws_iam_policy" "publish_to_discord_requests" {
  name = "${var.resource_prefix}publish_to_discord_requests"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "sqs:SendMessage"
      ],
      "Resource": ["${aws_sqs_queue.discord_requests.arn}"]
    }
  ]
}
EOF
}


resource "aws_iam_policy" "receive_message_from_discord_requests" {
  name = "${var.resource_prefix}receive_message_from_discord_requests"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ReceiveMessage"
      ],
      "Resource": ["${aws_sqs_queue.discord_requests.arn}"]
    }
  ]
}
EOF
}
