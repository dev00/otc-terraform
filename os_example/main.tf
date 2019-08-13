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

resource "openstack_compute_keypair_v2" "os_keypair" {
  name             = "${var.project}_pubkey"
  public_key       = "${var.public_key}"
}

module "vpc" {
  source           = "./vpc"
  project          = "${var.project}"
}

resource "openstack_compute_instance_v2" "instances" {
  # can later be replaced by a for_each, which is currenctly not implemented
  # for a resource - see 'Resource for_each' at
  # https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each
  count           = length(var.instances)

  name            = "${var.project}-${var.instances[count.index].name}"
  image_name      = "${var.instances[count.index].image}"
  flavor_name     = "s2.medium.2"
  security_groups = ["default","${openstack_networking_secgroup_v2.allow_ssh_grp.name}"]
  key_pair        = "${openstack_compute_keypair_v2.os_keypair.id}"
  network {
    uuid = "${module.vpc.network_id}"
  }
  metadata        = {
    env           = "testing"
    foo           = "bar"
  }
}

# Example how to generate an inventory for Ansible
# ToDo:
#   Generate a whole inventory
#   find out how to set user&key, probably merging with info from the instance definitions
#   add proper jumphost handling
resource "local_file" "ansible_inventory"{
  content     = templatefile("ansible_inventory.tpl", { instances="${openstack_compute_instance_v2.instances}"})
  filename    = "/tmp/foobar"
}
