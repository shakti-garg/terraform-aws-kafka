# terraform-aws-kafka
Terraform module which creates Kafka Messaging Cluster on AWS

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| broker\_node\_instancetype | Instance type for the Kafka brokers | `string` | `"m4.xlarge"` | no |
| broker\_node\_linux\_ami | AMI Id of the desired Linux OS for the instances. It currently supports only RHEL-based distro of Amazon Linux. | `string` | n/a | yes |
| create\_kafka\_cluster | Toggle to control if Kafka-Cluster should be created (it affects almost all resources) | `bool` | `true` | no |
| keypair\_name | Name of the Public/private key pair, which allows you to connect securely to your instance after it launches | `string` | n/a | yes |
| name | Logical name for the Kafka-Cluster deployment. This name will also be used to tag the individual broker instances,<br>  so it should be unique across other resources | `string` | n/a | yes |
| num\_brokers | Number of Kafka brokers to be deployed | `number` | `3` | no |
| tags | A list of tag blocks. Each element should have keys named key, value, and propagate\_at\_launch. | `list(map(string))` | `[]` | no |
| vpc\_id | ID of the existing VPC | `string` | n/a | yes |
| vpc\_subnet\_ids | List of one or more public subnets in your existing VPC, across which broker nodes will be deployed. It is ensured that<br>  brokers are spread across AZs | `list` | n/a | yes |
| whitelist\_cidrs | List of CIDRs to be whitelisted for Remote and SSH access to broker nodes | `list` | n/a | yes |
| zookeeper\_quorum | URL of already existing Zookeeper quorum Endpoint. If value matches empty string(default value),<br>  then embedded cluster of 3 zookeeper nodes(if num\_brokers >= 3), else 1 zookeeper node is launched. Further, it is ensured that<br>  zookeeper nodes are distributed across AZs | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc\_id | ID of the current VPC |
| vpc\_subnet\_ids | List of one or more public subnets in your current VPC, across which broker nodes are deployed |


(Documentation of Inputs and Outputs are generated using terraform-docs[https://github.com/segmentio/terraform-docs])


