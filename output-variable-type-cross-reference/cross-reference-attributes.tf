resource "aws_eip" "web_eip" {
  domain = "vpc"
}

resource "aws_security_group" "allow_tls" {
  name = "terraform-firewall"
}

output "public-ip" {
  value = aws_eip.web_eip.public_ip
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "${aws_eip.web_eip.public_ip}/32"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_iam_user" "iam_user" {
  name = var.username
}

resource "aws_instance" "web" {
  count           = var.instance_count
  ami             = var.ami
  instance_type   = var.environment == "production" ? var.prod_instance_type : var.dev_instance_type
  key_name        = "Terraform"
  security_groups = concat(var.security_groups, [aws_security_group.allow_tls.name])
  tags            = var.ec2_tags
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.web[0].id
  allocation_id = aws_eip.web_eip.id
}
