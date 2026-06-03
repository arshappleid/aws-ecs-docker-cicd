# Backend ECS Service Security Group
resource "aws_security_group" "backend_ecs" {
  name_prefix = "${var.project_name}-ecs-sg"
  description = "Security group for backend ECS service"
  vpc_id      = module.vpc.vpc_id

  tags = merge(var.tags, {
    Name = "${var.tags.Application}-backend-ecs-sg"
  })
}

# Allow ALB to access Backend
resource "aws_security_group_rule" "backend_from_alb" {
  type                     = "ingress"
  from_port                = var.service_1_config.container_port
  to_port                  = var.service_1_config.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.backend_ecs.id
  description              = "Allow ALB to access Backend ECS Service"
}

# Backend egress
resource "aws_security_group_rule" "backend_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_ecs.id
  description       = "Allow all outbound traffic"
}