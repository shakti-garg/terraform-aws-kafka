resource "aws_iam_instance_profile" "ec2_instance_profile" {
  count = var.create_kafka_cluster ? 1 : 0

  name = "${var.name}-broker-instance-role"
  role = "${aws_iam_role.ec2_role.*.name[0]}"
}

resource "aws_iam_role" "ec2_role" {
  count = var.create_kafka_cluster ? 1 : 0

  name = "${var.name}-broker-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_role_policy" {
  count = var.create_kafka_cluster ? 1 : 0

  name = "${var.name}-broker-role-policy"
  role = "${aws_iam_role.ec2_role.*.id[0]}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "ec2:CreateTags",
                "ec2:DescribeInstances"
            ]
        }
    ]
}
EOF
}