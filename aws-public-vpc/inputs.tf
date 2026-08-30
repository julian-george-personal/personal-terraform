variable "name" {
  type = string
}

variable "cidr_block" {
  type    = string
  default = "10.90.0.0/16"
}

variable "subnet_count" {
  type    = number
  default = 2
}
