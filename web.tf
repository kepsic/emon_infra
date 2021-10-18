data "template_file" "web" {
  template = file("web_data.tpl")
  vars = {
    aws_key        = var.access_key
    aws_secret     = var.secret_key
    mysql_user     = var.mysql_user
    mysql_password = var.mysql_password
    mysql_host     = aws_db_instance.lampstack_database_instance.address
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.web.rendered
  }
}


#create EC2 instance
resource "aws_instance" "lampstack_web_instance" {
  ami           = lookup(var.images, var.region)
  instance_type = "t2.micro"
  key_name      = "lampstack-key"

  # make sure you have your_private_ket.pem file
  vpc_security_group_ids = [
  aws_security_group.web_security_group.id]
  subnet_id = aws_subnet.lampstack_vpc_public_subnet.id
  tags = {
    Name = "lampstack_web_instance"
  }
  volume_tags = {
    Name = "lampstack_web_instance_volume"
  }
  user_data_base64 = data.template_cloudinit_config.config.rendered
  depends_on       = [aws_db_instance.lampstack_database_instance]
}


# create security group for web
resource "aws_security_group" "web_security_group" {
  name        = "web_security_group"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.lampstack_vpc.id
  tags = {
    Name = "lampstack_vpc_web_security_group"
  }
}

# create security group ingress rule for web
resource "aws_security_group_rule" "web_ingress" {
  count    = length(var.web_ports)
  type     = "ingress"
  protocol = "tcp"
  cidr_blocks = [
  "0.0.0.0/0"]
  from_port         = element(var.web_ports, count.index)
  to_port           = element(var.web_ports, count.index)
  security_group_id = aws_security_group.web_security_group.id
}

# create security group egress rule for web
resource "aws_security_group_rule" "web_egress" {
  count    = length(var.web_ports)
  type     = "egress"
  protocol = "tcp"
  cidr_blocks = [
  "0.0.0.0/0"]
  from_port         = element(var.web_ports, count.index)
  to_port           = element(var.web_ports, count.index)
  security_group_id = aws_security_group.web_security_group.id
}
