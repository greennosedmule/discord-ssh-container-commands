### SSH Lambda ###

resource "aws_iam_role" "labmda_run_ssh_command_role" {
  name = "${var.resource_prefix}labmda_run_ssh_command_role"

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


resource "aws_iam_policy" "invoke_run_ssh_command" {
  name = "${var.resource_prefix}invoke_run_ssh_command"

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
      "Resource": ["${aws_lambda_function.run_ssh_command.arn}"]
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "labmda_run_ssh_command_role_read_secret_ssh_key" {
  role       = aws_iam_role.labmda_run_ssh_command_role.name
  policy_arn = aws_iam_policy.read_secret_ssh_key.arn
}


resource "aws_iam_role_policy_attachment" "labmda_run_ssh_command_role_log_to_cloudwatch" {
  role       = aws_iam_role.labmda_run_ssh_command_role.name
  policy_arn = data.aws_iam_policy.send_logs_to_cloudwatch.arn
}


data "archive_file" "lambda_ssh" {
  type = "zip"
  source_content = templatefile("${path.module}/lambda/run-ssh-command/src/lambda_function.py.tmpl", {
    desthost       = var.ssh_destination_host
    destport       = var.ssh_destination_port
    proxyjumphost  = var.ssh_proxy_host
    proxyjumpport  = var.ssh_proxy_port
    sshkeysecretid = aws_secretsmanager_secret.ssh_key.name
    username       = "aws-operator"
  })
  source_content_filename = "lambda_function.py"
  output_path             = "${path.module}/.terraform/archive_file/lambda-run-ssh-command.zip"
}


data "archive_file" "lambda_layer_ssh" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/run-ssh-command/layer"
  output_path = "${path.module}/.terraform/archive_file/lambda-layer-run-ssh-command.zip"
}


resource "aws_lambda_layer_version" "run_ssh_command_reqs" {
  layer_name               = "${var.resource_prefix}run-ssh-command-reqs"
  filename                 = data.archive_file.lambda_layer_ssh.output_path
  source_code_hash         = data.archive_file.lambda_layer_ssh.output_base64sha256
  compatible_runtimes      = ["python3.9"]
  compatible_architectures = ["x86_64"]
}


resource "aws_lambda_function" "run_ssh_command" {
  filename         = data.archive_file.lambda_ssh.output_path
  function_name    = "${var.resource_prefix}Run-SSH-Command"
  role             = aws_iam_role.labmda_run_ssh_command_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_ssh.output_base64sha256
  layers = [
    aws_lambda_layer_version.run_ssh_command_reqs.arn
  ]
  runtime       = "python3.9"
  architectures = ["x86_64"]
  timeout       = 120
}


resource "aws_cloudwatch_log_group" "run_ssh_command_logs" {
  name              = "/aws/lambda/${aws_lambda_function.run_ssh_command.function_name}"
  retention_in_days = 7
}
