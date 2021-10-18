# create security group for db
resource "aws_security_group" "db_security_group" {
  name        = "db_security_group"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.lampstack_vpc.id
  tags = {
    Name = "lampstack_vpc_db_security_group"
  }
}
# create security group ingress rule for db
resource "aws_security_group_rule" "db_ingress" {
  count    = length(var.db_ports)
  type     = "ingress"
  protocol = "tcp"
  cidr_blocks = [
  "0.0.0.0/0"]
  from_port         = element(var.db_ports, count.index)
  to_port           = element(var.db_ports, count.index)
  security_group_id = aws_security_group.db_security_group.id
}
# create security group egress rule for db
resource "aws_security_group_rule" "db_egress" {
  count    = length(var.db_ports)
  type     = "egress"
  protocol = "tcp"
  cidr_blocks = [
  "0.0.0.0/0"]
  from_port         = element(var.db_ports, count.index)
  to_port           = element(var.db_ports, count.index)
  security_group_id = aws_security_group.db_security_group.id
}

# create aws rds subnet groups
resource "aws_db_subnet_group" "lampstack_database_subnet_group" {
  name = "mydbsg"
  subnet_ids = [
    aws_subnet.lampstack_vpc_private_subnet_one.id,
  aws_subnet.lampstack_vpc_private_subnet_two.id]
  tags = {
    Name = "lampstack_database_subnet_group"
  }
}
#create aws mysql rds instance
resource "aws_db_instance" "lampstack_database_instance" {
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.micro"
  port              = 3306
  vpc_security_group_ids = [
  aws_security_group.db_security_group.id]
  db_subnet_group_name = aws_db_subnet_group.lampstack_database_subnet_group.name
  name                 = "mydb"
  identifier           = "mysqldb"
  username             = var.mysql_user
  password             = var.mysql_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  tags = {
    Name = "lampstack_database_instance"
  }
}