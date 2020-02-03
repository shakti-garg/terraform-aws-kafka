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
  count              = "${var.num_brokers}"

  ami                = "${var.broker_node_linux_ami}"
  instance_type      = "${var.broker_node_instancetype}"

  placement_group    = "${aws_placement_group.partition_pg.id}"
  subnet_id          = "${var.vpc_subnet_ids[count.index % length(var.vpc_subnet_ids)]}"

  associate_public_ip_address   = true

  key_name                = "${var.keypair_name}"
  vpc_security_group_ids  = "${var.zookeeper_quorum == "" ? [aws_security_group.remote_ssh.id, aws_security_group.kafka_broker.id, aws_security_group.zookeeper_node.id] : [aws_security_group.remote_ssh.id, aws_security_group.kafka_broker.id]}"
  iam_instance_profile    = "${aws_iam_instance_profile.ec2_instance_profile.id}"

  user_data               = "${data.template_file.user_data_kafka_broker.rendered}"

  tags = {
      Name = "${var.name}-kafka-cluster-broker-${count.index}"
    }
}

locals {
  kafka_bootstrap_servers = "${join(",", formatlist("%s:9092", aws_instance.kafka_cluster.*.public_ip))}"
}


#wait for kafka-broker nodes to be initialized
resource "null_resource" "kafka_cluster_initialized" {
    triggers = {
        cluster_instance_ids = "${join(",", aws_instance.kafka_cluster.*.id)}"
    }

    provisioner "local-exec" {
        command = "until nc -zv ${element(aws_instance.kafka_cluster.*.public_ip, 0)} 9092; [ $? -eq 0 ]; do sleep 2; done"
    }
}

