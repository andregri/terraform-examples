output "endpoints" {
  value = <<EOF

Vault Server IP (public):  ${join(", ", aws_instance.vault-server.*.public_ip)}
Vault Server IP (private): ${join(", ", aws_instance.vault-server.*.private_ip)}

For example:
   ssh -i ${var.key_name}.pem ubuntu@${aws_instance.vault-server[0].public_ip}


Jenkins IP (public):  ${aws_instance.jenkins-node.public_ip}
Jenkins IP (private): ${aws_instance.jenkins-node.private_ip}

For example:
   ssh -i ${var.key_name}.pem ubuntu@${aws_instance.jenkins-node.public_ip}

EOF

}

output "vault-client-role-arn" {
  value = aws_iam_role.vault-client.arn
}