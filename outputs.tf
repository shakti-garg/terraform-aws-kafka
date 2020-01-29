output "vpc_id" {
  value = "${module.vpc.vpc_id}"
  description = "ID of the current VPC"
}

output "vpc_subnet_ids" {
  value = "${module.vpc.public_subnets}"
  description = "List of one or more public subnets in your current VPC, across which broker nodes are deployed"
}