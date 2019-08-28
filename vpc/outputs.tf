output "network_id" {
  value       = "${opentelekomcloud_networking_network_v2.os_network_1.id}"
  description = "The ID of the created network, can be used similar to the VPC ID when using the opentelekomcloud provider"
}
