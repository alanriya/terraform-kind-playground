variable "replicas" {
  type    = number
  default = 2
}

variable "image_repo" {
  type    = string
  default = "local/api"
}

variable "image_tag" {
  type    = string
  default = "dev"
}

variable "ingress_host" {
  type    = string
  default = "localhost"
}
