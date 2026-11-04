data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "web" {
  count = var.use_lab_instance_profile ? 0 : 1

  name               = "${local.name_prefix}-ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  description        = "Lecture du seul secret Parameter Store de ${var.environment}."

  tags = {
    Name        = "${local.name_prefix}-ec2"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "read_app_secret" {
  count = var.use_lab_instance_profile ? 0 : 1

  name = "read-novasphere-${var.environment}-app-secret"
  role = aws_iam_role.web[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = aws_ssm_parameter.app_secret.arn
    }]
  })
}

resource "aws_iam_instance_profile" "web" {
  count = var.use_lab_instance_profile ? 0 : 1

  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.web[0].name

  tags = {
    Name        = "${local.name_prefix}-ec2-profile"
    Environment = var.environment
  }
}
