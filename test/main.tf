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

module "kafka_cluster" {
  source  = "../"

  name    = "my-cluster"
  region  = "us-east-1"
  vpc_id  = "${module.vpc.vpc_id}"
  vpc_cidr = "${module.vpc.vpc_cidr_block}"
  vpc_subnet_ids  = "${module.vpc.public_subnets}"
  whitelist_ips  = ["171.48.45.220/32","14.142.34.138/32"]
  key_name  = "shakti"
  num_brokers = 3
  broker_node_ami = "ami-0b898040803850657"
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