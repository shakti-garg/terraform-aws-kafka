data "template_file" "user_data_zookeeper_node" {
  template = "${file("${path.module}/scripts/app_install.sh")}"

  vars = {
    app_types = "zookeeper_node"
  }
}

data "template_file" "user_data_kafka_broker" {
  template = "${file("${path.module}/scripts/app_install.sh")}"

  vars = {
    app_types = "${var.num_zookeepers == 0 ? "zookeeper_node,kafka_broker" : "kafka_broker"}"
  }
}

