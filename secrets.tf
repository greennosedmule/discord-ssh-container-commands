resource "aws_secretsmanager_secret" "ssh_key" {
  name = "${var.resource_prefix}ssh-key"
}


resource "aws_secretsmanager_secret_version" "ssh_key" {
  secret_id     = aws_secretsmanager_secret.ssh_key.id
  secret_string = file("${path.module}/ssh-key")
}


resource "aws_iam_policy" "read_secret_ssh_key" {
  name = "${var.resource_prefix}read_secret_ssh_key"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
      ],
      "Resource": ["${aws_secretsmanager_secret_version.ssh_key.arn}"]
    },
    {
      "Effect": "Allow",
      "Action": "secretsmanager:ListSecrets",
      "Resource": "*"
    }
  ]
}
EOF
}
