resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.name}-broker-instance-role"
  role = "${aws_iam_role.ec2_role.name}"
}

resource "aws_iam_role" "ec2_role" {
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