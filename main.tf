resource "aws_placement_group" "partition_pg" {
  name     = "partition_pg"
  strategy = "partition"
}

#==========Create Zookeeper nodes==================
resource "aws_autoscaling_group" "zookeeper_cluster" {
  name                      = "${var.name}-zookeeper-cluster"

  max_size                  = "${var.num_zookeepers}"
  min_size                  = "${var.num_zookeepers}"
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = "${var.num_zookeepers}"

  force_delete              = true
  placement_group           = "${aws_placement_group.partition_pg.id}"
  vpc_zone_identifier       = "${var.vpc_subnet_ids}"

  launch_configuration      = "${aws_launch_configuration.zk_node_launch_config.name}"

  tags = [{
    key                 = "Name"
    value               = "${var.name}-zookeeper-node"
    propagate_at_launch = true
  },{
    key                 = "project"
    value               = "${var.name}"
    propagate_at_launch = true
  }]
}

resource "aws_launch_configuration" "zk_node_launch_config" {
  name_prefix   = "${var.name}-zk-node-"
  image_id      = "${var.zookeeper_node_ami}"
  instance_type = "${var.broker_node_instancetype}"

  associate_public_ip_address = true
  key_name      = "${var.key_name}"
  security_groups = ["${aws_security_group.remote_ssh.id}", "${aws_security_group.zookeeper_node.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ec2_instance_profile.id}"

  user_data     = "${data.template_file.user_data_zookeeper_node.rendered}"
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

  tags = [{
    key                 = "Name"
    value               = "${var.name}-kafka-broker"
    propagate_at_launch = true
  },{
    key                 = "project"
    value               = "${var.name}"
    propagate_at_launch = true
  }]
}

resource "aws_launch_configuration" "broker_launch_config" {
  name_prefix   = "${var.name}-broker-"
  image_id      = "${var.broker_node_ami}"
  instance_type = "${var.zookeeper_node_instance_type}"

  associate_public_ip_address = true
  key_name      = "${var.key_name}"
  security_groups = ["${aws_security_group.remote_ssh.id}", "${aws_security_group.kafka_broker.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ec2_instance_profile.id}"

  user_data     = "${data.template_file.user_data_kafka_broker.rendered}"
}

