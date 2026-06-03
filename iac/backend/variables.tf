variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "prab-cicd-ecs"
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Owner       = "Prabhmeet"
    Terraform   = "true"
    project = "prab-cicd-ecs"
    Environment = "dev"
    project     = "prab-cicd-ecs"
    Application = "CICD-DEMO-API"
  }
}

# Logs Configuration
variable "logs_retention_config" {
  description = "Configuration for CloudWatch log retention"
  type        = map(any)
  default = {
    retention_in_days = 365
    class             = "INFREQUENT_ACCESS"
  }
}

variable "cluster_config" {
  description = "Configuration for the ECS cluster"
  type        = map(any)
  default = {
    spot_instance_percentage = 100
  }
}

# Legacy single-service config (kept for backwards compat with stage_ecs.tf)
variable "service_1_config" {
  description = "Config of the backend ECS service"
  type        = map(any)
  default = {
    name                   = "flask-api"
    service_cpu_allocation    = 1024
    service_memory_allocation = 2048
    container_port         = 80
    port_name              = "http"
    task_cpu_allocation    = 1024
    task_memory_allocation = 2048
    desired_count          = 1
    image                  = "866934333672.dkr.ecr.us-east-1.amazonaws.com/prab-cicd-backend:latest"
  }
}

# Cluster Configuration
variable "cluster_config" {
  description = "Configuration for the Fargate ECS cluster"
  type = object({
    spot_instance_percentage = optional(number, 50)
  })
  default = {}
}

# Services Configuration
variable "services" {
  description = "Map of ECS services to create with their configurations"
  type = map(object({
    container_port     = number
    health_check_path  = optional(string, "/health")
    desired_task_count = optional(number, 2)
    port_name          = optional(string, "http")

    # ALB Path-based Routing
    path_pattern       = optional(string)
    alb_route_priority = optional(number)
    strip_path_prefix  = optional(bool, true)

    # Task Definition Configuration
    task_family    = string
    container_name = optional(string, "api")
    image          = optional(string, "public.ecr.aws/docker/library/nginx:alpine")
    task_cpu       = optional(number, 256)
    task_memory    = optional(number, 512)

    # Placement Strategy
    placement_strategy = optional(list(object({
      type  = string
      field = string
      })), [
      {
        type  = "spread"
        field = "attribute:ecs.availability-zone"
      },
      {
        type  = "binpack"
        field = "memory"
      }
    ])

    # Deployment Configuration
    deployment_minimum_healthy_percent = optional(number, 50)
    deployment_maximum_percent         = optional(number, 200)

    # CI/CD Integration
    ignore_task_definition_changes = optional(bool, true)

    # ECS Exec
    enable_execute_command = optional(bool, false)
  }))
  default = {
    backend-dev = {
      container_port    = 80
      health_check_path = "/health"
      task_family       = "backend"
      image             = "866934333672.dkr.ecr.us-east-1.amazonaws.com/prab-cicd-backend:latest"
      path_pattern      = "/dev/*"
      alb_route_priority = 100
    }
    backend-stage = {
      container_port    = 80
      health_check_path = "/health"
      task_family       = "backend"
      image             = "866934333672.dkr.ecr.us-east-1.amazonaws.com/prab-cicd-backend:latest"
      path_pattern      = "/stage/*"
      alb_route_priority = 110
    }
  }

  validation {
    condition     = alltrue([for name, config in var.services : can(regex("^[a-z0-9-]+$", name))])
    error_message = "Service names must contain only lowercase letters, numbers, and hyphens."
  }
}

# ALB Configuration
variable "alb_listeners" {
  description = "Map of ALB listener configurations"
  type = map(object({
    port              = number
    protocol          = string
    certificate_arn   = optional(string)
    ssl_policy        = optional(string, "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09")
    redirect_to_https = optional(bool, false)
  }))
  default = {
    http = {
      port     = 80
      protocol = "HTTP"
    }
  }
}

variable "alb_default_target_service" {
  description = "The service name to use as the default ALB target group (must be a key in var.services)"
  type        = string
  default     = "backend-dev"
}

# Security Group Configuration
variable "alb_security_group_ingress" {
  description = "Map of ingress rules for ALB security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {
    http = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from internet"
    }
  }
}

variable "ecs_security_group_ingress" {
  description = "Map of ingress rules for backend ECS instances security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))
  default = {
    dynamic_ports = {
      from_port   = 32768
      to_port     = 65535
      protocol    = "tcp"
      description = "Dynamic container ports from ALB only"
    }
  }
}



# Scaling Policy Configuration
variable "scale_up_cpu_threshold" {
  description = "CPU percentage threshold to trigger scale up"
  type        = number
  default     = 70
}
