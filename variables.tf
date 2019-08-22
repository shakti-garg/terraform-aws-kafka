variable "name" {
  type	= string
}

variable "region" {
  type  = string
}

variable "vpc_id" {
  type	= string
}

variable "vpc_cidr" {
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

variable "zookeeper_quorum" {
  default = ""
}

variable "tags" {
  description = "A list of tag blocks. Each element should have keys named key, value, and propagate_at_launch."
  type        = list(map(string))
  default     = []
}