// creating the aws_iam_role
resource "aws_iam_role" "aws_role" {
  name = "${var.env}-${var.component}-role"


  assume_role_policy = jsonencode({
    Version          = "2012-10-17"
    Statement        = [
      {
        Action       = "sts:AssumeRole"
        Effect       = "Allow"
        Sid          = ""
        Principal    = {
          Service    = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge (local.common_tags, { Name = "${var.env}-${var.component}-role" } )

}

resource "aws_iam_instance_profile" "para_instance_profile" {
  role = aws_iam_role.aws_role.name
  name = "${var.env}-${var.component}-role"
}

resource "aws_iam_policy" "aws_parameter_policy" {
  name        = "${var.env}-${var.component}-parameter_store_role"
  path        = "/"
  description = "${var.env}-${var.component}-parameter_store_role"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource" : [
          "arn:aws:ssm:us-east-1:490686900756:parameter/${var.env}.${var.component}*",
          "arn:aws:ssm:us-east-1:490686900756:parameter/nexus*"
        ]
      },
      {
        "Sid": "VisualEditor1",
        "Effect": "Allow",
        "Action": "ssm:DescribeParameters",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.aws_role.name
  policy_arn = aws_iam_policy.aws_parameter_policy.arn
}


resource "aws_security_group" "main" {
  name        = "${var.env}-${var.component}_security_group"
  description = "${var.env}-${var.component}-security-group"
  vpc_id      = var.vpc_id


  ingress {
    description      = "HTTP"
    from_port        = var.app_port
    to_port          = var.app_port
    protocol         = "tcp"
    cidr_blocks      = var.allow_cidr

  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_cidr

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge (local.common_tags, { Name = "${var.env}-${var.component}-security-group" } )

}



resource "aws_launch_template" "launch_template" {
  name                   = "${var.env}-${var.component}-launch_template"
  image_id               = data.aws_ami.ami_id.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  user_data = base64encode(templatefile("${path.module}/user_data.sh",{component=var.component,env=var.env} ))

  iam_instance_profile {
    arn = aws_iam_instance_profile.para_instance_profile.arn
  }

  instance_market_options {
    market_type = "spot"

  }
}

resource "aws_autoscaling_group" "auto_scaling_group" {
  name                      = "${var.env}-${var.component}-autoscaling-group"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  force_delete              = true
  vpc_zone_identifier       = var.subnet_ids

  launch_template {
    id = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each              = local.all_tags
    content {
      key                 = tag.value.key
      value               = tag.value.value
      propagate_at_launch = true
    }
  }

}