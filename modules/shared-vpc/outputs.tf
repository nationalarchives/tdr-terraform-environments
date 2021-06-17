output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public.*.id
}

output "public_subnet_ranges" {
  value = aws_subnet.public.*.cidr_block
}

output "private_subnets" {
  value = aws_subnet.private.*.id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.gw.*.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}

output "nat_gateway_public_ips" {
  value = aws_nat_gateway.gw.*.public_ip
}

output "default_nacl_id" {
  value = aws_vpc.main.default_network_acl_id
}