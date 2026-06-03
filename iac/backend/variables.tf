

variable "project_name" {
  type        = string
  description = "Name of the project, used for naming resources"
  default     = "my-project"
}

variable "tags" {
  type = map(string)
  default = {
    owner        = "owner"
    project_name = "my-project"
  }
}

