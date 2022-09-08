output "web_server_public_ip" {
  value = <<EOF
  To connect   ssh -i vault-kp.pem ubuntu@${aws_instance.web_server.public_ip}
  EOF
}

output "db_address" {
  value = aws_db_instance.appdb.address
}