variable "project" {
  type    = string
  default = ""
}

variable "vpc_cidr" {
  default = "192.168.0.0/16"
}
variable "subnet_1_cidr" {
  default = "192.168.10.0/24"
}
variable "subnet_1_gw" {
  default = "192.168.10.1"
}

variable "dns_servers" {
  type    = list
  default = ["9.9.9.9", "8.8.8.8"]
}

variable "external_network_id" {
  default = "0a2228f2-7f8a-45f1-8e09-9039e1d09975"
}
