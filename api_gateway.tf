resource "aws_api_gateway_rest_api" "discord_rest" {
  name = "${var.resource_prefix}discord-rest"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_account" "discord_rest_account" {
  depends_on          = [aws_iam_role_policy_attachment.api_gateway_role_send_logs_to_cloudwatch]
  cloudwatch_role_arn = aws_iam_role.api_gateway_discord_rest.arn
}

resource "aws_api_gateway_deployment" "discord_rest_deployment" {
  rest_api_id = aws_api_gateway_rest_api.discord_rest.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.discord_rest.body,
      aws_api_gateway_integration.discord_rest_container_post_lambda.request_templates,
      aws_api_gateway_integration.discord_rest_container_post_lambda.uri,
      aws_api_gateway_integration_response.discord_rest_response_model_200.response_templates,
      aws_api_gateway_integration_response.discord_rest_response_model_401.response_templates,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "discord_rest_logs" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.discord_rest.id}/${var.api_gateway_stage_name}"
  retention_in_days = 7
}

resource "aws_api_gateway_stage" "discord_rest_stage" {
  depends_on    = [aws_cloudwatch_log_group.discord_rest_logs]
  deployment_id = aws_api_gateway_deployment.discord_rest_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.discord_rest.id
  stage_name    = var.api_gateway_stage_name
}

resource "aws_api_gateway_method_settings" "discord_rest_all" {
  depends_on  = [aws_api_gateway_account.discord_rest_account]
  rest_api_id = aws_api_gateway_rest_api.discord_rest.id
  stage_name  = aws_api_gateway_stage.discord_rest_stage.stage_name
  method_path = "*/*"

  settings {
    logging_level = "INFO"
  }
}

resource "aws_api_gateway_resource" "discord_rest_discord" {
  parent_id   = aws_api_gateway_rest_api.discord_rest.root_resource_id
  path_part   = "discord"
  rest_api_id = aws_api_gateway_rest_api.discord_rest.id
}

resource "aws_api_gateway_resource" "discord_rest_container" {
  parent_id   = aws_api_gateway_resource.discord_rest_discord.id
  path_part   = "container"
  rest_api_id = aws_api_gateway_rest_api.discord_rest.id
}

resource "aws_api_gateway_method" "discord_rest_container_post" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.discord_rest_container.id
  rest_api_id   = aws_api_gateway_rest_api.discord_rest.id
}

resource "aws_api_gateway_integration" "discord_rest_container_post_lambda" {
  http_method             = aws_api_gateway_method.discord_rest_container_post.http_method
  integration_http_method = "POST"
  resource_id             = aws_api_gateway_resource.discord_rest_container.id
  rest_api_id             = aws_api_gateway_rest_api.discord_rest.id
  type                    = "AWS"
  uri                     = aws_lambda_function.discord_handler.invoke_arn

  request_templates = {
    "application/json" = file("${path.module}/templates/integration_request.json")
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "${var.resource_prefix}AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.discord_rest.execution_arn}/*/*/*"
}

resource "aws_api_gateway_method_response" "discord_rest_response_200" {
  rest_api_id = aws_api_gateway_rest_api.discord_rest.id
  resource_id = aws_api_gateway_resource.discord_rest_container.id
  http_method = aws_api_gateway_method.discord_rest_container_post.http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "discord_rest_response_401" {
  rest_api_id = aws_api_gateway_rest_api.discord_rest.id
  resource_id = aws_api_gateway_resource.discord_rest_container.id
  http_method = aws_api_gateway_method.discord_rest_container_post.http_method
  status_code = "401"
}

resource "aws_api_gateway_integration_response" "discord_rest_response_model_200" {
  rest_api_id = aws_api_gateway_rest_api.discord_rest.id
  resource_id = aws_api_gateway_resource.discord_rest_container.id
  http_method = aws_api_gateway_method.discord_rest_container_post.http_method
  status_code = aws_api_gateway_method_response.discord_rest_response_200.status_code

  response_templates = {
    "application/json" = file("${path.module}/templates/integration_response.json")
  }
}

resource "aws_api_gateway_integration_response" "discord_rest_response_model_401" {
  rest_api_id = aws_api_gateway_rest_api.discord_rest.id
  resource_id = aws_api_gateway_resource.discord_rest_container.id
  http_method = aws_api_gateway_method.discord_rest_container_post.http_method
  status_code = aws_api_gateway_method_response.discord_rest_response_401.status_code

  selection_pattern = ".*UNAUTHORIZED.*"
}

resource "aws_iam_role" "api_gateway_discord_rest" {
  name = "${var.resource_prefix}api_gateway_discord_rest"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "apigateway.amazonaws.com"
                ]
            },
            "Action": [
                "sts:AssumeRole"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "api_gateway_role_send_logs_to_cloudwatch" {
  role       = aws_iam_role.api_gateway_discord_rest.name
  policy_arn = data.aws_iam_policy.send_logs_to_cloudwatch.arn
}
