output "broker_list" {
  value = "${join(",", formatlist("%s:9092", aws_instance.kafka_cluster.*.public_ip))}"
}