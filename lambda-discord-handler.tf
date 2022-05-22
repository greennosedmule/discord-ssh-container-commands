### Handler lambda ###

resource "aws_iam_role" "lambda_discord_handler_role" {
  name = "${var.resource_prefix}lambda_discord_handler_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "lambda_discord_handler_role_invoke_discord_authorizer" {
  role       = aws_iam_role.lambda_discord_handler_role.name
  policy_arn = aws_iam_policy.invoke_discord_authorizer.arn
}


resource "aws_iam_role_policy_attachment" "labmda_discord_handler_role_publish_to_discord_requests" {
  role       = aws_iam_role.lambda_discord_handler_role.name
  policy_arn = aws_iam_policy.publish_to_discord_requests.arn
}


resource "aws_iam_role_policy_attachment" "labmda_discord_handler_role_log_to_cloudwatch" {
  role       = aws_iam_role.lambda_discord_handler_role.name
  policy_arn = data.aws_iam_policy.send_logs_to_cloudwatch.arn
}


data "archive_file" "lambda_discord_handler" {
  type = "zip"
  source_content = templatefile("${path.module}/lambda/discord-handler/src/lambda_function.py.tmpl", {
    aws_region     = var.aws_region
    authorizer_arn = aws_lambda_function.discord_authorizer.arn
    sqs_queue_url  = aws_sqs_queue.discord_requests.url
  })
  source_content_filename = "lambda_function.py"
  output_path             = "${path.module}/.terraform/archive_file/lambda-discord-handler.zip"
}


resource "aws_lambda_function" "discord_handler" {
  filename         = data.archive_file.lambda_discord_handler.output_path
  function_name    = "${var.resource_prefix}Discord-Handler"
  role             = aws_iam_role.lambda_discord_handler_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_discord_handler.output_base64sha256
  runtime          = "python3.9"
  architectures    = ["x86_64"]
  timeout          = 120
}


resource "aws_cloudwatch_log_group" "lambda_discord_handler_logs" {
  name              = "/aws/lambda/${aws_lambda_function.discord_handler.function_name}"
  retention_in_days = 7
}
