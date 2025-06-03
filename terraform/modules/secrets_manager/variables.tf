variable "project_name" {
  description = "The name of the project, used for tagging and naming resources."
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, prod), used for tagging and naming resources."
  type        = string
}

variable "tags" {
  description = "A map of common tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}

