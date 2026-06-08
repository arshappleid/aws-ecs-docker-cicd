# ---------------------------------------------------------------------------
# ECS Task Role – assumed by the running container
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "backend_task_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backend_task_role" {
  name               = "${var.project_name}-backend-task-role"
  assume_role_policy = data.aws_iam_policy_document.backend_task_assume_role.json

  tags = var.tags
}

# --- SSM Parameter Store ---------------------------------------------------

data "aws_iam_policy_document" "backend_task_ssm" {
  statement {
    sid    = "SSMParameterStore"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/${var.project_name}/*",
      "arn:aws:ssm:us-east-1:*:parameter/prab/aws-ecs-cicd/*"
      ]
  }
}

resource "aws_iam_policy" "backend_task_ssm" {
  name   = "${var.project_name}-backend-task-ssm"
  policy = data.aws_iam_policy_document.backend_task_ssm.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backend_task_ssm" {
  role       = aws_iam_role.backend_task_role.name
  policy_arn = aws_iam_policy.backend_task_ssm.arn
}

# --- CloudWatch Logs -------------------------------------------------------

data "aws_iam_policy_document" "backend_task_cloudwatch" {
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "cloudwatch:PutMetricData",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "backend_task_cloudwatch" {
  name   = "${var.project_name}-backend-task-cloudwatch"
  policy = data.aws_iam_policy_document.backend_task_cloudwatch.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backend_task_cloudwatch" {
  role       = aws_iam_role.backend_task_role.name
  policy_arn = aws_iam_policy.backend_task_cloudwatch.arn
}

# --- S3 --------------------------------------------------------------------

data "aws_iam_policy_document" "backend_task_s3" {
  statement {
    sid    = "S3ObjectOperations"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::${var.project_name}-*/*"]
  }

  statement {
    sid    = "S3BucketOperations"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = ["arn:aws:s3:::${var.project_name}-*"]
  }
}

resource "aws_iam_policy" "backend_task_s3" {
  name   = "${var.project_name}-backend-task-s3"
  policy = data.aws_iam_policy_document.backend_task_s3.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backend_task_s3" {
  role       = aws_iam_role.backend_task_role.name
  policy_arn = aws_iam_policy.backend_task_s3.arn
}
