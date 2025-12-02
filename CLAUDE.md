# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project provides Infrastructure-as-Code (IaC) to automatically provision and configure a privacy-focused Tailscale exit node hosted in Europe (Finland/Switzerland). The goal is to enable secure internet access from alternative geographic locations with one-command deployment and teardown.

## Technology Stack

- **Infrastructure**: Terraform with Hetzner Cloud provider (hetznercloud/hcloud)
- **Configuration**: Cloud-init for initial server setup
- **OS**: Ubuntu 24.04 LTS
- **VPN**: Tailscale (WireGuard-based)
- **Hosting**: Hetzner (Helsinki) or Infomaniak (Switzerland)
- **Target Server**: CX11 (1 vCPU, 2GB RAM, 20TB traffic/month, ~€3-5/month)

## Project Structure

```
terraform/
├── main.tf              # Main Terraform configuration (provider, resources)
├── variables.tf         # Input variables (hcloud_token, ssh_public_key, etc.)
├── outputs.tf           # Output values (IPs, server ID, next steps)
├── terraform.tfvars     # Variable values (gitignored - contains secrets)
└── cloud-init.yaml      # Cloud-init configuration for initial setup
```

## Common Commands

### Terraform Operations
- `terraform init` - Initialize Terraform and download providers
- `terraform plan` - Preview infrastructure changes
- `terraform apply` - Deploy/update infrastructure
- `terraform destroy` - Tear down all resources
- `terraform output` - Display output values (IPs, server info)

### Testing and Validation
- `terraform validate` - Validate Terraform syntax
- `terraform fmt` - Format Terraform files
- `cloud-init schema --config-file terraform/cloud-init.yaml` - Validate cloud-init syntax

### Server Access
- `ssh root@<server-ip>` - SSH into the provisioned server (root access with keys enabled)
- `sudo tailscale status` - Check Tailscale connection status
- `sudo ufw status` - Check firewall status

## Architecture Overview

### Infrastructure Layer
- Terraform provisions a VPS on Hetzner Cloud using the hcloud provider
- SSH keys are configured for secure access (password auth disabled)
- Firewall rules allow only SSH (port 22) and Tailscale (UDP 41641)
- Public IPv4 and IPv6 addresses are assigned

### Configuration Layer (Cloud-init)
- Cloud-init runs once at first boot to configure the server
- Stages:
  1. **System Preparation**: Update packages, install curl/ufw/fail2ban
  2. **SSH Security**: Disable password authentication (keys only), keep root login with keys enabled
  3. **Network**: Enable IP forwarding (sysctl), configure UFW firewall
  4. **Tailscale**: Install Tailscale, enable service (manual auth required)

### Exit Node Functionality
- IP forwarding is enabled to route traffic
- Tailscale advertises the node as an exit node
- Manual authentication required (security best practice - no auth keys in repo)
- User must approve exit node in Tailscale admin console
- Client devices can then route all traffic through this node

## Important Constraints

### Security
- **No secrets in git**: terraform.tfvars and .tfstate files must be gitignored
- **Manual Tailscale auth**: Cannot automate auth keys (must SSH and authenticate manually)
- **SSH Access**: Root login with keys enabled (secure for single-user), password auth disabled
- **Ubuntu 24.04 default**: `PermitRootLogin prohibit-password` (allows keys, blocks passwords)
- **Minimal attack surface**: Only SSH and Tailscale ports open

### Scope Limitations
- **Single server only**: No high availability or load balancing
- **Personal use**: Not designed for multiple users
- **Immutable infrastructure**: No ongoing config management (deploy/destroy model)
- **No monitoring**: Basic setup only (can add Prometheus/Grafana later)

## Development Workflow

### Initial Implementation Order (from PRD)
1. Set up Terraform project structure
2. Implement basic VPS provisioning (main.tf, variables.tf)
3. Add cloud-init configuration (user setup, security, network)
4. Add firewall rules (UFW configuration)
5. Add Tailscale installation to cloud-init
6. Add outputs and documentation
7. Test deployment end-to-end

### File Creation Order
1. variables.tf - Define all input variables
2. main.tf - Provider config, SSH key resource, server resource
3. cloud-init.yaml - Complete initialization script
4. outputs.tf - Server IPs, ID, and next steps
5. .gitignore - Exclude secrets and state files
6. README.md - User-facing setup instructions

## Key Implementation Details

### Variables to Define (variables.tf)
- `hcloud_token` (sensitive) - Hetzner API token
- `ssh_public_key` - Public SSH key for access
- `server_name` - Default: null (auto-generates as "tailscale-exit-{location}")
- `server_type` - Default: "cx11" (Note: May need to use "cx23" - check Hetzner console for current types)
- `location` - Default: "hel1" (Helsinki)
- `image` - Default: "ubuntu-24.04"

### Cloud-init Must Include
- System updates and security packages
- Disable password authentication (keep root key-based access enabled)
- Note: Ubuntu 24.04 defaults to `PermitRootLogin prohibit-password` (secure)
- IP forwarding: `net.ipv4.ip_forward=1` and `net.ipv6.conf.all.forwarding=1`
- UFW: default deny incoming, allow SSH, allow Tailscale UDP 41641
- UFW forwarding policy: set to ACCEPT (required for exit node)
- NAT/IP masquerading: iptables MASQUERADE rule for exit node traffic
- iptables-persistent: to persist NAT rules across reboots
- Fail2ban for SSH brute-force protection
- Tailscale installation script from https://tailscale.com/install.sh
- Enable tailscaled service
- Privacy hardening: disable IP forwarding logs, reduce log retention

### Firewall Rules (must be explicit)
- Allow SSH (port 22) from anywhere
- Allow Tailscale UDP (port 41641) from anywhere
- Default deny all other incoming
- Default allow all outgoing
- UFW forwarding: ACCEPT (for exit node functionality)

### NAT/Masquerading Configuration
- iptables rule: `-A POSTROUTING -o eth0 -j MASQUERADE`
- Applied automatically via cloud-init
- Persisted via iptables-persistent package
- Required for exit node to route traffic to internet

## Deployment Flow

1. User creates terraform.tfvars with their credentials
2. User runs `terraform apply` - VPS provisions in ~3-5 minutes
3. Cloud-init runs automatically on first boot (~2 minutes)
4. User SSHs to server and runs Tailscale authentication
5. User approves exit node in Tailscale admin console
6. User enables exit node on client devices

## Post-Deployment Manual Steps

After Terraform completes, user must:
1. SSH into server: `ssh root@<output-ip>`
2. Authenticate Tailscale: `sudo tailscale up --advertise-exit-node --accept-routes --netfilter-mode=off`
3. Visit Tailscale admin console and approve exit node
4. Enable exit node on client device to start routing traffic

Important: Do NOT use `--shields-up` flag - it prevents exit node advertisement

## Cost Constraints

- Monthly hosting must not exceed $5 USD
- Hetzner CX11 is ~€3.29/month (~$3.50 USD)
- Tailscale free tier is sufficient (3 users, 100 devices)

## Privacy Design

- **Location**: Finland (GDPR protections) or Switzerland (strong privacy laws)
- **No logging**: Exit node does not log traffic
- **Encrypted**: All traffic encrypted via WireGuard protocol
- **No central server**: Tailscale uses peer-to-peer mesh networking
