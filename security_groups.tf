resource "aws_security_group" "remote_ssh" {
  count       = var.create_kafka_cluster ? 1 : 0

  name        = "remote_ssh_security_group"
  description = "Allow ssh traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.whitelist_cidrs}"
  }
}

resource "aws_security_group" "kafka_broker" {
  count       = var.create_kafka_cluster ? 1 : 0

  name        = "kafka_broker_security_group"
  description = "Allow kafka traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = "${concat([data.aws_vpc.current.cidr_block], var.whitelist_cidrs)}"
  }

  ingress {
    from_port   = 19092
    to_port     = 19092
    protocol    = "tcp"
    self = true
  }

    egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "zookeeper_node" {
  count       = var.create_kafka_cluster ? 1 : 0

  name        = "zookeeper_node_security_group"
  description = "Allow zookeeper traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = "${concat([data.aws_vpc.current.cidr_block], var.whitelist_cidrs)}"
  }

  ingress {
    from_port   = 2888
    to_port     = 2888
    protocol    = "tcp"
    self = true
  }

  ingress {
    from_port   = 3888
    to_port     = 3888
    protocol    = "tcp"
    self = true
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
