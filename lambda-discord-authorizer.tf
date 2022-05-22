### Authorizer Lambda ###

resource "aws_iam_role" "labmda_discord_authorizer_role" {
  name = "${var.resource_prefix}labmda_discord_authorizer_role"

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


resource "aws_iam_policy" "invoke_discord_authorizer" {
  name = "${var.resource_prefix}invoke_discord_authorizer"

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
      "Resource": ["${aws_lambda_function.discord_authorizer.arn}"]
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "labmda_discord_authorizer_role_log_to_cloudwatch" {
  role       = aws_iam_role.labmda_discord_authorizer_role.name
  policy_arn = data.aws_iam_policy.send_logs_to_cloudwatch.arn
}


data "archive_file" "lambda_discord_authorizer" {
  type = "zip"
  source_content = templatefile("${path.module}/lambda/discord-authorizer/src/lambda_function.py.tmpl", {
    discord_public_key = var.discord_public_key
  })
  source_content_filename = "lambda_function.py"
  output_path             = "${path.module}/.terraform/archive_file/lambda-discord-authorizer.zip"
}


data "archive_file" "lambda_layer_discord_authorizer" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/discord-authorizer/layer"
  output_path = "${path.module}/.terraform/archive_file/lambda-layer-discord-authorizer.zip"
}


resource "aws_lambda_layer_version" "discord_authorizer" {
  layer_name               = "${var.resource_prefix}discord-authorizer-reqs"
  filename                 = data.archive_file.lambda_layer_discord_authorizer.output_path
  source_code_hash         = data.archive_file.lambda_layer_discord_authorizer.output_base64sha256
  compatible_runtimes      = ["python3.9"]
  compatible_architectures = ["x86_64"]
}


resource "aws_lambda_function" "discord_authorizer" {
  filename         = data.archive_file.lambda_discord_authorizer.output_path
  function_name    = "${var.resource_prefix}Discord-Authorizer"
  role             = aws_iam_role.labmda_discord_authorizer_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_discord_authorizer.output_base64sha256
  layers = [
    aws_lambda_layer_version.discord_authorizer.arn
  ]
  runtime       = "python3.9"
  architectures = ["x86_64"]
}


resource "aws_cloudwatch_log_group" "discord_authorizer_logs" {
  name              = "/aws/lambda/${aws_lambda_function.discord_authorizer.function_name}"
  retention_in_days = 7
}
