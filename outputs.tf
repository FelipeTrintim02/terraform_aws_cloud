output "web_public_ip" {
    description = "The public IP address of the web server"
    value = aws_eip.eip.public_ip
    depends_on = [aws_eip.eip]
}

output "web_public_dns" {
    description = "The public DNS address of the web server"
    value = aws_eip.eip.public_dns
    depends_on = [aws_eip.eip]
}

output "database_endpoint"{
    description = "The endpoint of the database"
    value = aws_db_instance.database.endpoint
}

output "database_port"{
    description = "The port of the database"
    value = aws_db_instance.database.port
}

output "postgres_connection_string" {
  description = "postgres connection string with all info"
  sensitive = true
  value = "postgresql://${aws_db_instance.database.username}:${aws_db_instance.database.password}@${aws_db_instance.database.address}:${aws_db_instance.database.port}/${aws_db_instance.database.db_name}?sslmode=require"
}

output "link_to_web" {
  description = "link to web app"
  value = "http://${aws_lb.lb.dns_name}/docs"
}

output "dashboard_url" {
    value = "http://${coalesce(module.loadtest-distribuited.leader_public_ip, module.loadtest-distribuited.leader_private_ip)}:8089"
    description = "The URL of the Locust UI."
}