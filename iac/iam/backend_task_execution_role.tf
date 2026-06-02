# ---------------------------------------------------------------------------
# ECS Task Execution Role – used by the ECS agent to launch the container
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "backend_task_execution_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backend_task_execution_role" {
  name               = "${var.project_name}-backend-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.backend_task_execution_assume_role.json

  tags = var.tags
}

# Attach the AWS managed policy that covers ECR pull + basic CloudWatch logs
resource "aws_iam_role_policy_attachment" "backend_task_execution_managed" {
  role       = aws_iam_role.backend_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow the execution role to read SSM parameters for secrets injection
data "aws_iam_policy_document" "backend_task_execution_ssm" {
  statement {
    sid    = "SSMSecretsAccess"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = ["arn:aws:ssm:*:*:parameter/${var.project_name}/*"]
  }

  statement {
    sid    = "KMSDecryptSSM"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "backend_task_execution_ssm" {
  name   = "${var.project_name}-backend-task-execution-ssm"
  policy = data.aws_iam_policy_document.backend_task_execution_ssm.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backend_task_execution_ssm" {
  role       = aws_iam_role.backend_task_execution_role.name
  policy_arn = aws_iam_policy.backend_task_execution_ssm.arn
}
