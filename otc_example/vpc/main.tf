resource "opentelekomcloud_vpc_v1" "otc_vpc" {
  name            = "${var.project}-vpc"
  cidr            = "${var.vpc_cidr}"
  shared          = true

}
resource "opentelekomcloud_vpc_subnet_v1" "otc_subnet_1" {
  name            = "${var.project}-subnet1"
  cidr            = "${var.subnet_1_cidr}"
  gateway_ip      = "${var.subnet_1_gw}"
  vpc_id          = "${opentelekomcloud_vpc_v1.otc_vpc.id}"
  primary_dns     = "${var.dns_servers[0]}"
  secondary_dns   = "${var.dns_servers[1]}"
}
