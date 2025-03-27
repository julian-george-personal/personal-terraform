variable "app_name" {
  type = string
}

variable "env_secrets" {
  type = map(string)
  default = {
  }
}

variable "env_vars" {
  type = map(string)
  default = {
  }
}