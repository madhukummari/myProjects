
####################### NACL for VPC ##########################
resource "aws_network_acl" "nacl" {
  vpc_id = var.vpc_id
}
resource "aws_network_acl_rule" "inbound_ssh" {
  network_acl_id = aws_network_acl.nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "inbound_http" {
  network_acl_id = aws_network_acl.nacl.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "inbound_https" {
  network_acl_id = aws_network_acl.nacl.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}
resource "aws_network_acl_rule" "outbound_all" {
  network_acl_id = aws_network_acl.nacl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}


################################ IAM Role for SSM ##########################
data "aws_iam_policy" "ssmpolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ssmrole" {
  name = "SSMRole"
  assume_role_policy = jsonencode(({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"

        }
      }
    ]
  }))

}
resource "aws_iam_role_policy_attachment" "ssmattachment" {
  role       = aws_iam_role.ssmrole.name
  policy_arn = data.aws_iam_policy.ssmpolicy.arn
}

############################## security group for alb web and app servers ##########################
locals {
  layers = {
    alb = {
      ports       = [80, 443]
      source_cidr = "0.0.0.0/0"
    }

    web = {
      ports        = [80]
      source_layer = "alb"
    }

    app = {
      ports        = [8080, 8081]
      source_layer = "web"
    }

    db = {
      ports        = [3306]
      source_layer = "app"
    }
  }
}

resource "aws_security_group" "security_groups" {
  for_each = local.layers

  name        = "${var.project_name}-${each.key}-sg"
  description = "Security group for ${each.key} layer"
  vpc_id      = var.vpc_id
  dynamic "ingress" {
    for_each = each.value.ports
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      cidr_blocks     = each.value.source_cidr != null ? [each.value.source_cidr] : null                                          # aws_security_group.security_groups[web].id terraform reads resources like this
      security_groups = each.value.source_layer != null ? [aws_security_group.security_groups[each.value.source_layer].id] : null # reference  chat in chat gpt "Terraform AZ Logic"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}