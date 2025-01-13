variable "app_name" {
  type = string
}

variable "is_dns_enabled" {
    default = false
}

variable "hosted_zone_id" {
    default = null
    type = string
}

variable "domain_name" {
    default = null
  type = string
}