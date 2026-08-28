variable "bucket_name" {
  type = string
}

variable "versioning_enabled" {
  type    = bool
  default = false
}

variable "force_destroy" {
  type    = bool
  default = false
}
