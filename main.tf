
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
  name_prefix   = "${var.env}-${var.component}-launch_template"
  image_id      = data.aws_ami.ami_id.id
  instance_type = var.instance_type
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
    for_each = local.all_tags
    content {
      key = tag.value.key
      value = tag.value.value
      propagate_at_launch = true
    }
  }

}