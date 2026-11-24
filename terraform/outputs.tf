output "puppet_master_private_ip" {
  description = "Private IP address of the Puppet Master instance"
  value       = aws_instance.puppet_master.private_ip
}

output "puppet_agent_private_ip" {
  description = "Private IP address of the Puppet Agent instance"
  value       = aws_instance.puppet_agent.private_ip
}

output "ansible_monitoring_private_ip" {
  description = "Private IP address of the Ansible / Nagios instance"
  value       = aws_instance.ansible_monitoring.private_ip
}
