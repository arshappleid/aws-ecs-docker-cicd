variable "project_name" {
  type = string
  default = "prab-cicd-ecs"
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Owner       = "Prabhmeet"
    Terraform   = "true"
    project = "prab-cicd-ecs"
    Environment = "dev"
    Application = "CICD-DEMO-API"
  }
}
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

variable "service_1_config" {
  description = "Name & Config of the second ECS service"
  type        = map(any)
  default = {
    name = "backend"

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