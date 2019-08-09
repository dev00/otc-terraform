variable "auth_url" {
	type		= string
	default	=	"https://iam.eu-de.otc.t-systems.com:443/v3"
}
variable "project" {
  type		= string
	default	=	"TFTEST"
}

variable "vpc_cidr" {
  default	= "192.168.0.0/16"
}
variable "subnet_1_cidr" {
  default	= "192.168.10.0/24"
}
variable "subnet_1_gw" {
  default	= "192.168.10.1"
}

variable "dns_servers" {
	type		= list
	default	= ["9.9.9.9", "8.8.8.8"]
}

variable "public_key" {}

variable "instances" {
	type		= list
	default = [{
			"name"   = "ubuntu1604"
			"image"	 = "Standard_Ubuntu_16.04_latest"
		},
		{
			"name"   = "ubuntu1804"
			"image"	 = "Standard_Ubuntu_18.04_latest"
		},
		{
			"name"   = "ubuntu1604-tsi"
			"image"	 = "Community_Ubuntu_16.04_TSI_latest"
		},
		{
			"name"   = "centos7"
			"image"	 = "Standard_CentOS_7_latest"
		},
		{
			"name"   = "rhel7"
			"image"	 = "Enterprise_RedHat_7_latest"
		}
	]
}

provider "opentelekomcloud" {
}

resource "opentelekomcloud_compute_secgroup_v2" "otc_allow_ssh" {
  name		= "${var.project}-allow_ssh"
  description	= "allowing ssh from everywhere"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "opentelekomcloud_vpc_v1" "otc_vpc" {
  name		= "${var.project}-vpc"
  cidr		= "${var.vpc_cidr}"
	shared	= true

}
resource "opentelekomcloud_vpc_subnet_v1" "otc_subnet_1" {
  name						= "${var.project}-subnet1"
  cidr						= "${var.subnet_1_cidr}"
  gateway_ip			= "${var.subnet_1_gw}"
  vpc_id					= "${opentelekomcloud_vpc_v1.otc_vpc.id}"
	primary_dns			=	"${var.dns_servers[0]}"
	secondary_dns		= "${var.dns_servers[1]}"
}

resource "opentelekomcloud_compute_keypair_v2" "otc_keypair" {
	name					= "${var.project}_pubkey"
  public_key		= "${var.public_key}"
}

resource "opentelekomcloud_compute_instance_v2" "instances" {
	# can later be replaced by a for_each, which is currenctly not implemented
	# for a resource - see 'Resource for_each' at
	# https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each
	count						= length(var.instances)

  name						= "${var.project}-${var.instances[count.index].name}"
  image_name			= "${var.instances[count.index].image}"
  flavor_name			= "s2.medium.2"
  security_groups = ["default","${opentelekomcloud_compute_secgroup_v2.otc_allow_ssh.id}"]
  key_pair				= "${opentelekomcloud_compute_keypair_v2.otc_keypair.id}"
  network {
    uuid = "${opentelekomcloud_vpc_subnet_v1.otc_subnet_1.id}"
  }
	tag		 = {
		env					= "testing"
		foo					= "bar"
	}
}
