provider "opentelekomcloud" {
}

resource "opentelekomcloud_compute_secgroup_v2" "otc_allow_ssh" {
  name    = "${var.project}-allow_ssh"
  description = "allowing ssh from everywhere"

  rule {
    from_port     = max(5,8,22)
    to_port       = 22
    ip_protocol   = "tcp"
    cidr          = "0.0.0.0/0"
  }
}

module "vpc" {
  source          = "./vpc"
  project         = "${var.project}"
}

resource "opentelekomcloud_compute_keypair_v2" "otc_keypair" {
  name            = "${var.project}_pubkey"
  public_key      = "${var.public_key}"
}

resource "opentelekomcloud_compute_instance_v2" "instances" {
  # can later be replaced by a for_each, which is currenctly not implemented
  # for a resource - see 'Resource for_each' at
  # https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each
  count           = length(var.instances)

  name            = "${var.project}-${var.instances[count.index].name}"
  image_name      = "${var.instances[count.index].image}"
  flavor_name     = "s2.medium.2"
  security_groups = ["default","${opentelekomcloud_compute_secgroup_v2.otc_allow_ssh.name}"]
  key_pair        = "${opentelekomcloud_compute_keypair_v2.otc_keypair.id}"
  network {
    uuid          = "${module.vpc.vpc_id}"
  }
  tag             = {
    env           = "testing"
    foo           = "bar"
  }
}
