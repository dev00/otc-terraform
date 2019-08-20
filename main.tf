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

resource "openstack_compute_instance_v2" "test_instances" {
  # can later be replaced by a for_each, which is currenctly not implemented
  # for a resource - see 'Resource for_each' at
  # https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each
  count           = length(var.instances)

  name            = "${var.project}-${var.instances[count.index].name}"
  image_name      = "${var.instances[count.index].image}"
  flavor_name     = "s2.medium.2"
  security_groups = ["default"]
  key_pair        = "${openstack_compute_keypair_v2.os_keypair.id}"
  network {
    uuid = "${module.vpc.network_id}"
  }
  metadata        = {
    env           = "testing"
    foo           = "bar"
    login_user    = "${var.instances[count.index].login_user}"
    commit_id     = "none"
  }
}

resource "openstack_compute_instance_v2" "bastion" {
  # can later be replaced by a for_each, which is currenctly not implemented
  # for a resource - see 'Resource for_each' at
  # https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each
  name            = "${var.project}-bastion"
  image_name      = "${var.bastion_image}"
  flavor_name     = "s2.medium.2"
  security_groups = ["default","${openstack_networking_secgroup_v2.allow_ssh_grp.name}"]
  key_pair        = "${openstack_compute_keypair_v2.os_keypair.id}"

  network {
    uuid = "${module.vpc.network_id}"
  }
  metadata        = {
    env           = "bastion"
  }
}

#resource "opentelekomcloud_compute_floatingip_v2" "bastion_eip" {
#  pool = "admin_external_net"
#}

resource "openstack_networking_floatingip_v2" "bastion_eip" {
    pool = "admin_external_net"
}

resource "opentelekomcloud_compute_floatingip_associate_v2" "bastion_eip_assoc" {
  floating_ip    = "${openstack_networking_floatingip_v2.bastion_eip.address}"
  instance_id    = "${openstack_compute_instance_v2.bastion.id}"
}

# Example how to generate an inventory for Ansible
# ToDo:
#   find out whether it's possible to generate a full inventory via tf, respecting the groups set via metadata
#   if not, wait for https://github.com/terraform-providers/terraform-provider-openstack/issues/836 to be fixed
resource "local_file" "ansible_inventory" {
  content     = templatefile("ansible_inventory.tpl", { instances="${openstack_compute_instance_v2.test_instances}", bastion = "${openstack_compute_instance_v2.bastion}", bastion_ip="${openstack_networking_floatingip_v2.bastion_eip.address}", bastion_user="${var.bastion_user}"})
  filename    = "${var.ansible_inventory}"
}
