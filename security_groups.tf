resource "aws_security_group" "remote_ssh" {
  name        = "remote_ssh_security_group"
  description = "Allow ssh traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.whitelist_ips}"
  }
}

resource "aws_security_group" "kafka_broker" {
  name        = "kafka_broker_security_group"
  description = "Allow kafka traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = "${concat([var.vpc_cidr], var.whitelist_ips)}"
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
  name        = "zookeeper_node_security_group"
  description = "Allow zookeeper traffic"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = "${concat([var.vpc_cidr], var.whitelist_ips)}"
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
