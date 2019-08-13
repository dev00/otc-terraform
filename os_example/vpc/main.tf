resource "openstack_networking_network_v2" "os_network_1" {
  name              = "${var.project}-network"
  admin_state_up    = true
  dns_domain        = "eu-de.compute.internal."
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

