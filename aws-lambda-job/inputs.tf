variable "function_name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "handler" {
  type    = string
  default = "index.handler"
}

variable "runtime" {
  type    = string
  default = "nodejs22.x"
}

variable "env_vars" {
  type    = map(string)
  default = {}
}

variable "env_secrets" {
  type    = map(string)
  default = {}
}

variable "max_concurrent_executions" {
  type    = number
  default = -1
}
