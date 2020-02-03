output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "vpc_subnet_ids" {
  value = "${module.vpc.public_subnets}"
}

output "kafka_bootstrap_servers" {
  value = "${module.kafka_cluster.bootstrap_servers}"
}