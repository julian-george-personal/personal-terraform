variable "task_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "schedule_expression" {
  type = string
}

variable "command" {
  type    = list(string)
  default = null
}

variable "env_vars" {
  type    = map(string)
  default = {}
}

variable "env_secrets" {
  type    = map(string)
  default = {}
}

variable "log_retention_days" {
  type    = number
  default = 14
}
