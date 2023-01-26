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

output "private_backend_checks_subnets" {
  value = aws_subnet.private_backend_checks.*.id
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

output "elastic_ip_arns" {
  value = [
    "arn:aws:ec2:eu-west-2:${data.aws_caller_identity.current.account_id}:eip-allocation/${aws_eip.gw[0].id}",
    "arn:aws:ec2:eu-west-2:${data.aws_caller_identity.current.account_id}:eip-allocation/${aws_eip.gw[1].id}",
  ]
}
