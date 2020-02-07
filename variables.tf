variable "create_kafka_cluster" {
  type        = bool
  default     = true
  description = "Toggle to control if Kafka-Cluster should be created (it affects almost all resources)"
}

variable "name" {
  type	= string
  description = <<EOT
  Logical name for the Kafka-Cluster deployment. This name will also be used to tag the individual broker instances,
  so it should be unique across other resources
  EOT
}

variable "vpc_id" {
  type	= string
  description = "ID of the existing VPC"
}

variable "vpc_subnet_ids" {
  type  = list
  description = <<EOT
  List of one or more public subnets in your existing VPC, across which broker nodes will be deployed. It is ensured that
  brokers are spread across AZs
  EOT
}

variable "whitelist_cidrs" {
  type	= list
  description = "List of CIDRs to be whitelisted for Remote and SSH access to broker nodes"
}

variable "keypair_name" {
  type  = string
  description = "Name of the Public/private key pair, which allows you to connect securely to your instance after it launches"
}

variable "num_brokers" {
  default = 3
  description = "Number of Kafka brokers to be deployed"
}

variable "broker_node_linux_ami" {
  type  = string
  description = "AMI Id of the desired Linux OS for the instances. It currently supports only RHEL-based distro of Amazon Linux."
}

variable "broker_node_instancetype" {
  default = "m4.xlarge"
  description = "Instance type for the Kafka brokers"
}

variable "zookeeper_quorum" {
  default = ""
  description = <<EOT
  URL of already existing Zookeeper quorum Endpoint. If value matches empty string(default value),
  then embedded cluster of 3 zookeeper nodes(if num_brokers >= 3), else 1 zookeeper node is launched. Further, it is ensured that
  zookeeper nodes are distributed across AZs
  EOT
}

variable "tags" {
  type        = list(map(string))
  default     = []
  description = "A list of tag blocks. Each element should have keys named key, value, and propagate_at_launch."
}