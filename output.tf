#output webserver and dbserver address
output "db_server_address" {
  value = aws_db_instance.lampstack_database_instance.address
}
output "web_server_address" {
  value = aws_instance.lampstack_web_instance.public_dns
}