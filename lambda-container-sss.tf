### SSS lambda ###

resource "aws_iam_role" "lambda_container_sss_role" {
  name = "${var.resource_prefix}lambda_container_sss_role"

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


resource "aws_iam_policy" "invoke_container_sss" {
  name = "${var.resource_prefix}invoke_container_sss"

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
      "Resource": ["${aws_lambda_function.container_sss.arn}"]
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "lambda_container_sss_role_invoke_run_ssh_command" {
  role       = aws_iam_role.lambda_container_sss_role.name
  policy_arn = aws_iam_policy.invoke_run_ssh_command.arn
}


resource "aws_iam_role_policy_attachment" "labmda_container_sss_role_log_to_cloudwatch" {
  role       = aws_iam_role.lambda_container_sss_role.name
  policy_arn = data.aws_iam_policy.send_logs_to_cloudwatch.arn
}


data "archive_file" "lambda_container_sss" {
  type = "zip"
  source_content = templatefile("${path.module}/lambda/container-sss/src/lambda_function.py.tmpl", {
    ssh_arn = aws_lambda_function.run_ssh_command.arn
  })
  source_content_filename = "lambda_function.py"
  output_path             = "${path.module}/.terraform/archive_file/lambda-container-sss.zip"
}


resource "aws_lambda_function" "container_sss" {
  filename         = data.archive_file.lambda_container_sss.output_path
  function_name    = "${var.resource_prefix}Container-SSS"
  role             = aws_iam_role.lambda_container_sss_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_container_sss.output_base64sha256
  runtime          = "python3.9"
  architectures    = ["x86_64"]
  timeout          = 120
}


resource "aws_cloudwatch_log_group" "container_sss_logs" {
  name              = "/aws/lambda/${aws_lambda_function.container_sss.function_name}"
  retention_in_days = 7
}
