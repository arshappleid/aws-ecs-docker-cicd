variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources into"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Name of the project, used for naming resources"
  default     = "prab-cicd"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default = {
    owner        = "owner"
    project_name = "my-project"
    Application = "demo-cicd-api"
  }
}