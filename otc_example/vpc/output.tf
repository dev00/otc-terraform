output "vpc_id" {
  value       = "${opentelekomcloud_vpc_subnet_v1.otc_subnet_1.id}"
  description = "The name of the created subnet"
}
