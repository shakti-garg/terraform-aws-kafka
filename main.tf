data "aws_region" "current" { }

data "aws_vpc" "current" {
  id = "${var.vpc_id}"
}

data "template_file" "user_data_kafka_broker" {
  template = "${file("${path.module}/scripts/app_install.sh")}"

  vars = {
    region    = "${data.aws_region.current.name}"
    kafka_autoscaling_group_name = "${var.name}-kafka-cluster"
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
resource "aws_autoscaling_group" "kafka_cluster" {
  name                      = "${var.name}-kafka-cluster"

  max_size                  = "${var.num_brokers}"
  min_size                  = "${var.num_brokers}"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = "${var.num_brokers}"

  force_delete              = true
  placement_group           = "${aws_placement_group.partition_pg.id}"
  vpc_zone_identifier       = "${var.vpc_subnet_ids}"

  launch_configuration      = "${aws_launch_configuration.broker_launch_config.name}"

  tags = concat(
    var.tags,
    [{
        key                 = "Name"
        value               = "${var.name}-kafka-broker"
        propagate_at_launch = true
      },{
        key                 = "project"
        value               = "${var.name}"
        propagate_at_launch = true
      },{
        key                 = "app-type"
        value               = "${var.zookeeper_quorum == "" ? "kafka-broker,embedded-zookeeper-node" : "kafka-broker"}"
        propagate_at_launch = true
    }]
   )
}

resource "aws_launch_configuration" "broker_launch_config" {
  name_prefix   = "${var.name}-broker-"
  image_id      = "${var.broker_node_linux_ami}"
  instance_type = "${var.broker_node_instancetype}"

  associate_public_ip_address = true
  key_name      = "${var.keypair_name}"
  security_groups = "${var.zookeeper_quorum == "" ? [aws_security_group.remote_ssh.id, aws_security_group.kafka_broker.id, aws_security_group.zookeeper_node.id] : [aws_security_group.remote_ssh.id, aws_security_group.kafka_broker.id]}"
  iam_instance_profile = "${aws_iam_instance_profile.ec2_instance_profile.id}"

  user_data     = "${data.template_file.user_data_kafka_broker.rendered}"
}

