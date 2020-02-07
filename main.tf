data "aws_region" "current" { }

data "aws_vpc" "current" {
  id = "${var.vpc_id}"
}

data "template_file" "user_data_kafka_broker" {
  template = "${file("${path.module}/scripts/app_install.sh")}"

  vars = {
    region    = "${data.aws_region.current.name}"
    kafka_broker_prefix = "${var.name}-kafka-cluster-broker"
    num_brokers = "${var.num_brokers}"
    zookeeper_quorum = "${var.zookeeper_quorum}"
    num_embedded_zks = "${var.zookeeper_quorum == "" ? (var.num_brokers >= 3 ? 3 : 1) : 0}"
  }
}

resource "aws_placement_group" "partition_pg" {
  name     = "partition_pg"
  strategy = "partition"
}

#==========Create Kafka Broker nodes==================
resource "aws_instance" "kafka_cluster" {
  count              = "${var.create_kafka_cluster ? var.num_brokers : 0}"

  ami                = "${var.broker_node_linux_ami}"
  instance_type      = "${var.broker_node_instancetype}"

  placement_group    = "${aws_placement_group.partition_pg.id}"
  subnet_id          = "${var.vpc_subnet_ids[count.index % length(var.vpc_subnet_ids)]}"

  associate_public_ip_address   = true

  key_name                = "${var.keypair_name}"
  vpc_security_group_ids  = "${var.zookeeper_quorum == "" ? [aws_security_group.remote_ssh.*.id[0], aws_security_group.kafka_broker.*.id[0], aws_security_group.zookeeper_node.*.id[0]] : [aws_security_group.remote_ssh.*.id[0], aws_security_group.kafka_broker.*.id[0]]}"
  iam_instance_profile    = "${aws_iam_instance_profile.ec2_instance_profile.*.id[0]}"

  user_data               = "${data.template_file.user_data_kafka_broker.rendered}"

  tags = {
      Name = "${var.name}-kafka-cluster-broker-${count.index}"
    }
}

#wait for kafka-broker nodes to be initialized
resource "null_resource" "kafka_cluster_initialized" {
    count = var.create_kafka_cluster ? 1 : 0

    triggers = {
        cluster_instance_ids = "${join(",", aws_instance.kafka_cluster.*.id)}"
    }

    provisioner "local-exec" {
        command = "${path.module}/scripts/wait_for_resource.sh ${join(",", aws_instance.kafka_cluster.*.public_ip)} 9092"
    }
}

data "aws_instances" "embedded_zk_nodes" {
  count = var.create_kafka_cluster ? 1 : 0

  depends_on = ["null_resource.kafka_cluster_initialized"]

  instance_tags = {
    Apps = "zookeeper-node,kafka-broker"
  }
}

locals {
  kafka_bootstrap_servers   = var.create_kafka_cluster ? "${join(",", formatlist("%s:9092", aws_instance.kafka_cluster.*.public_ip))}" : ""
  zookeeper_quorum          = var.create_kafka_cluster ? "${var.zookeeper_quorum == "" ? join(",", formatlist("%s:2181", length(data.aws_instances.embedded_zk_nodes) > 0 ? data.aws_instances.embedded_zk_nodes[0].public_ips : [])) : var.zookeeper_quorum}" : ""
}