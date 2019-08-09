variable "auth_url" {
  type    = string
  default = "https://iam.eu-de.otc.t-systems.com:443/v3"
}
variable "project" {
  type    = string
  default = "TFTEST"
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

provider "openstack" {
}

resource "openstack_networking_secgroup_v2" "allow_ssh_grp" {
  name    = "${var.project}-allow_ssh"
  description = "allowing ssh from everywhere"
}

resource "openstack_networking_secgroup_rule_v2" "allow_ssh_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.allow_ssh_grp.id}"
}

resource "openstack_networking_network_v2" "os_network_1" {
  name              = "${var.project}-network"
  admin_state_up    = true
}

resource "openstack_networking_subnet_v2" "os_subnet_1" {
  name              = "${var.project}-subnet1"
  cidr              = "${var.subnet_1_cidr}"
  dns_nameservers   = "${var.dns_servers}"
  gateway_ip        = "${var.subnet_1_gw}"
  network_id        = "${openstack_networking_network_v2.os_network_1.id}"
}

resource "openstack_networking_router_v2" "os_router" {
  # calling the router vpc, because that's the name that will show up
  # in the Web Interface. Calling it router may confuse people
  name             = "${var.project}-vpc"
  admin_state_up   = true
  external_network_id = "${var.external_network_id}"
  enable_snat      = true
}

resource "openstack_networking_router_interface_v2" "os_router_if" {
  router_id        = "${openstack_networking_router_v2.os_router.id}"
  subnet_id        = "${openstack_networking_subnet_v2.os_subnet_1.id}"
}

resource "openstack_compute_keypair_v2" "os_keypair" {
  name             = "${var.project}_pubkey"
  public_key       = "${var.public_key}"
}

resource "openstack_compute_instance_v2" "instances" {
  # can later be replaced by a for_each, which is currenctly not implemented
  # for a resource - see 'Resource for_each' at
  # https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each
  count           = length(var.instances)

  name            = "${var.project}-${var.instances[count.index].name}"
  image_name      = "${var.instances[count.index].image}"
  flavor_name     = "s2.medium.2"
  security_groups = ["default","${openstack_networking_secgroup_v2.allow_ssh_grp.id}"]
  key_pair        = "${openstack_compute_keypair_v2.os_keypair.id}"
  network {
    uuid = "${openstack_networking_network_v2.os_network_1.id}"
  }
  metadata        = {
    env           = "testing"
    foo           = "bar"
  }
}
