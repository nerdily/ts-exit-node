# Hetzner Cloud API Token
# Get this from: https://console.hetzner.cloud/ -> Security -> API Tokens
variable "hcloud_token" {
  description = "Hetzner Cloud API token (read & write permissions required)"
  type        = string
  sensitive   = true
}

# SSH public key for server access
# Use your existing key or generate: ssh-keygen -t ed25519
variable "ssh_public_key" {
  description = "SSH public key for accessing the server"
  type        = string
}

# Server configuration
variable "server_name" {
  description = "Name for the VPS instance (defaults to 'tailscale-exit-{location}' if not specified)"
  type        = string
  default     = null
}

variable "server_type" {
  description = "Hetzner server type (CX11 = 1 vCPU, 2GB RAM, €3.29/month)"
  type        = string
  default     = "cx11"
}

variable "location" {
  description = "Hetzner datacenter location (hel1=Helsinki, fsn1=Falkenstein, nbg1=Nuremberg)"
  type        = string
  default     = "hel1"
}

variable "image" {
  description = "OS image to use"
  type        = string
  default     = "ubuntu-24.04"
}

# Admin user configuration
variable "admin_username" {
  description = "Admin username for SSH access (non-root)"
  type        = string
  default     = "admin"
}
