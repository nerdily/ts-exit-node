terraform {
  required_version = ">= 1.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

# Compute server name: use provided name or auto-generate from location
locals {
  server_name = var.server_name != null ? var.server_name : "tailscale-exit-${var.location}"
}

# Upload SSH public key to Hetzner
resource "hcloud_ssh_key" "default" {
  name       = "${local.server_name}-key"
  public_key = var.ssh_public_key
}

# Create the VPS instance
resource "hcloud_server" "exit_node" {
  name        = local.server_name
  server_type = var.server_type
  location    = var.location
  image       = var.image

  # Attach SSH key for access
  ssh_keys = [hcloud_ssh_key.default.id]

  # Cloud-init configuration for initial setup
  user_data = file("${path.module}/cloud-init.yaml")

  # Labels for organization
  labels = {
    purpose = "tailscale-exit-node"
    managed = "terraform"
  }

  # Enable both IPv4 and IPv6
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}

# Firewall rules
resource "hcloud_firewall" "exit_node" {
  name = "${local.server_name}-firewall"

  # Allow SSH from anywhere
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # Allow Tailscale (WireGuard) UDP traffic
  rule {
    direction = "in"
    protocol  = "udp"
    port      = "41641"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

# Attach firewall to server
resource "hcloud_firewall_attachment" "exit_node" {
  firewall_id = hcloud_firewall.exit_node.id
  server_ids  = [hcloud_server.exit_node.id]
}
