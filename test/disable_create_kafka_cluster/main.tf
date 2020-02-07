module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 2.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
  enable_dns_hostnames = true

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.0.0/19", "10.0.32.0/19"]

  tags = {
    Environment = "test"
  }
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "test-dev"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtHFN/OhAvJtSM4B0wo2NLGkcawfCwL+48nP1p5756eNZ3/o7sd0nz0RPUvHG3CZI6MBdrm/ZmDphDQO3Bm3DpCNQHdtF1IDvpe/zpwtOlJWJTZA2O52x96CfI6OIIi664s5ojYRJQ/8Tks4cyzEE3dFLSo+t2izMvxzPuBGjWlLI+1eeouWKgwUNZp1udkfSROpD2W9BWiKbNWKoKV6zWR/gq3UrTO6qwn+QKzs39ioSUnCGyRn9CfhDw2iN/H/inV8F7/tt1jvryZIYXkkFOb6YPBLw8BwhtZg0jPCdCzS0tVOaC/ybzCYD6vKtH22ak4Y+Xc0EpLsdZ4rjdOz0/ shaktig@INshaktig.local"
}

module "kafka_cluster" {
  source  = "../../"

  create_kafka_cluster = false

  name    = "my-cluster"
  vpc_id  = "${module.vpc.vpc_id}"
  vpc_subnet_ids  = "${module.vpc.public_subnets}"
  whitelist_cidrs  = ["223.179.152.208/32","14.142.34.138/32"]
  keypair_name  = "${aws_key_pair.ssh_key.key_name}"
  num_brokers = 2
  broker_node_linux_ami = "ami-0b898040803850657"
  broker_node_instancetype = "t3.medium"
  zookeeper_quorum = ""

  tags = [
    {
      key                 = "Environment"
      value               = "test"
      propagate_at_launch = true
    }
  ]
}