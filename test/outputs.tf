output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "vpc_subnet_ids" {
  value = "${module.vpc.public_subnets}"
}