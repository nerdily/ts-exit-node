# Output server information after deployment

output "server_id" {
  description = "Hetzner server ID"
  value       = hcloud_server.exit_node.id
}

output "server_name" {
  description = "Server name"
  value       = hcloud_server.exit_node.name
}

output "server_ipv4" {
  description = "Server public IPv4 address"
  value       = hcloud_server.exit_node.ipv4_address
}

output "server_ipv6" {
  description = "Server public IPv6 address"
  value       = hcloud_server.exit_node.ipv6_address
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh root@${hcloud_server.exit_node.ipv4_address}"
}

output "next_steps" {
  description = "Next steps to complete the setup"
  value       = <<-EOT

    ========================================
    Deployment Complete!
    ========================================

    Server Details:
    - Name: ${hcloud_server.exit_node.name}
    - IPv4: ${hcloud_server.exit_node.ipv4_address}
    - IPv6: ${hcloud_server.exit_node.ipv6_address}
    - Location: ${var.location}

    Next Steps:

    1. Wait ~2 minutes for cloud-init to complete setup

    2. SSH into the server:
       ssh root@${hcloud_server.exit_node.ipv4_address}

    3. Authenticate Tailscale as exit node:
       sudo tailscale up --advertise-exit-node --accept-routes --netfilter-mode=off

    4. Approve exit node in Tailscale admin console:
       https://login.tailscale.com/admin/machines

       - Find "${hcloud_server.exit_node.name}"
       - Under "Routing Settings" → "Exit Node" → Click "Edit"
       - Set to "Allowed"

    5. Enable exit node on your client device:
       - Open Tailscale app
       - Select "${hcloud_server.exit_node.name}" as exit node
       - Verify your IP shows as ${var.location}

    Useful Commands:
    - Check Tailscale status: sudo tailscale status
    - Check firewall: sudo ufw status
    - View cloud-init logs: sudo cat /var/log/cloud-init-output.log

    ========================================
  EOT
}
