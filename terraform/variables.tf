# Hetzner Cloud API Token
# Get this from: https://console.hetzner.cloud/ -> Security -> API Tokens
variable "hcloud_token" {
  description = "Hetzner Cloud API token (read & write permissions required)"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[A-Za-z0-9]{64}$", var.hcloud_token))
    error_message = "Hetzner API token must be exactly 64 alphanumeric characters. Check your token from Hetzner Console -> Security -> API Tokens"
  }
}

# SSH public key for server access
# Use your existing key or generate: ssh-keygen -t ed25519
variable "ssh_public_key" {
  description = "SSH public key for accessing the server"
  type        = string

  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521) ", var.ssh_public_key))
    error_message = "SSH public key must start with a valid key type (ssh-rsa, ssh-ed25519, or ecdsa-sha2-*). Make sure you're using the PUBLIC key (*.pub file), not the private key."
  }
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

  validation {
    condition     = can(regex("^[a-z]{2,4}\\d+$", var.server_type))
    error_message = "Server type must match Hetzner's format: 2-4 letters followed by numbers (e.g., cx11, cx23, ccx13, cpx31). Check available types at https://www.hetzner.com/cloud"
  }
}

variable "location" {
  description = "Hetzner datacenter location (hel1=Helsinki, fsn1=Falkenstein, nbg1=Nuremberg)"
  type        = string
  default     = "hel1"

  validation {
    condition     = can(regex("^[a-z]{3}\\d{1,2}(-dc\\d{1,2})?$", var.location))
    error_message = "Location must match Hetzner's format: 3 letters + 1-2 digits, optionally followed by -dc## (e.g., hel1, fsn1, nbg1, fsn1-dc14). Check available locations at https://docs.hetzner.com/cloud/general/locations"
  }
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
