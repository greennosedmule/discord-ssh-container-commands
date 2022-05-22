resource "aws_sqs_queue" "discord_requests" {
  name                       = "${var.resource_prefix}Discord-Requests"
  visibility_timeout_seconds = 120 # needs to match lambda trigger
  # delay_seconds             = 90
  # max_message_size          = 2048
  # message_retention_seconds = 86400
  # receive_wait_time_seconds = 10
  # redrive_policy = jsonencode({
  #   deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
  #   maxReceiveCount     = 4
  # })
  # redrive_allow_policy = jsonencode({
  #   redrivePermission = "byQueue",
  #   sourceQueueArns   = [aws_sns_topic.discord_requests.arn]
  # })


  ### *** TODO *** HOW DO WE ADD A LAMBDA TRIGGER? ###
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
