### Responder lambda ###


resource "aws_iam_role" "lambda_discord_responder_role" {
  name = "${var.resource_prefix}lambda_discord_responder_role"

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


resource "aws_iam_policy" "invoke_discord_responder" {
  name = "${var.resource_prefix}invoke_discord_responder"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "lambda:invokeFunction",
          "lambda:invokeAsync"
      ],
      "Resource": ["${aws_lambda_function.discord_responder.arn}"]
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "lambda_discord_responder_role_invoke_container_sss" {
  role       = aws_iam_role.lambda_discord_responder_role.name
  policy_arn = aws_iam_policy.invoke_container_sss.arn
}


resource "aws_iam_role_policy_attachment" "lambda_discord_responder_role_receive_message_from_discord_requests" {
  role       = aws_iam_role.lambda_discord_responder_role.name
  policy_arn = aws_iam_policy.receive_message_from_discord_requests.arn
}


data "archive_file" "lambda_layer_discord_responder" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/discord-responder/layer"
  output_path = "${path.module}/.terraform/archive_file/lambda-layer-discord-responder.zip"
}


resource "aws_iam_role_policy_attachment" "labmda_discord_responder_role_log_to_cloudwatch" {
  role       = aws_iam_role.lambda_discord_responder_role.name
  policy_arn = data.aws_iam_policy.send_logs_to_cloudwatch.arn
}


resource "aws_lambda_layer_version" "discord_responder" {
  layer_name               = "${var.resource_prefix}discord-responder-reqs"
  filename                 = data.archive_file.lambda_layer_discord_responder.output_path
  source_code_hash         = data.archive_file.lambda_layer_discord_responder.output_base64sha256
  compatible_runtimes      = ["python3.9"]
  compatible_architectures = ["x86_64"]
}


data "archive_file" "lambda_discord_responder" {
  type = "zip"
  source_content = templatefile("${path.module}/lambda/discord-responder/src/lambda_function.py.tmpl", {
    container_arn = aws_lambda_function.container_sss.arn
  })
  source_content_filename = "lambda_function.py"
  output_path             = "${path.module}/.terraform/archive_file/lambda-discord-responder.zip"
}


resource "aws_lambda_function" "discord_responder" {
  filename         = data.archive_file.lambda_discord_responder.output_path
  function_name    = "${var.resource_prefix}Discord-Responder"
  role             = aws_iam_role.lambda_discord_responder_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_discord_responder.output_base64sha256
  layers = [
    aws_lambda_layer_version.discord_responder.arn
  ]
  runtime       = "python3.9"
  architectures = ["x86_64"]
  timeout       = 120
}


resource "aws_cloudwatch_log_group" "lambda_discord_responder_logs" {
  name              = "/aws/lambda/${aws_lambda_function.discord_responder.function_name}"
  retention_in_days = 7
}
