variable "project_name" {
  type        = string
  description = "Name of the project, used for naming IAM resources"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default     = {}
}
