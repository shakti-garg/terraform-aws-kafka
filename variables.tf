variable "name" {
  type	= string
}

variable "region" {
  type  = string
}

variable "vpc_id" {
  type	= string
}

variable "vpc_subnet_ids" {
  type  = list
}

variable "whitelist_ips" {
  type	= list
}

variable "key_name" {
  type  = string
}

variable "num_brokers" {
  default = 3
}

variable "broker_node_ami" {
  type  = string
}

variable "broker_node_instancetype" {
  default = "m4.xlarge"
}

variable "num_zookeepers" {
  default = 0
}

variable "zookeeper_node_ami" {
  type  = string
}

variable "zookeeper_node_instance_type" {
  default = "t2.micro"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}