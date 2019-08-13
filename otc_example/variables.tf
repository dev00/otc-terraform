variable "auth_url" {
  type    = string
  default = "https://iam.eu-de.otc.t-systems.com:443/v3"
}
variable "project" {
  type    = string
  default = "TFTEST"
}

variable "public_key" {}

variable "instances" {
  type    = list
  default = [{
      "name"   = "ubuntu1604"
      "image"  = "Standard_Ubuntu_16.04_latest"
    },
    {
      "name"   = "ubuntu1804"
      "image"  = "Standard_Ubuntu_18.04_latest"
    },
    {
      "name"   = "ubuntu1604-tsi"
      "image"  = "Community_Ubuntu_16.04_TSI_latest"
    },
    {
      "name"   = "centos7"
      "image"  = "Standard_CentOS_7_latest"
    },
    {
      "name"   = "rhel7"
      "image"  = "Enterprise_RedHat_7_latest"
    }
  ]
}
