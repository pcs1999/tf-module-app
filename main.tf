
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



