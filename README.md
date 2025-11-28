# Tailscale Exit Node - Automated Deployment

Automatically provision and configure a privacy-focused Tailscale exit node in Europe using [Terraform](https://developer.hashicorp.com/terraform) and [Hetzner Cloud](https://www.hetzner.com/cloud/).

## Overview

This project deploys a VPS in Helsinki, Finland that acts as a Tailscale exit node, allowing you to route your internet traffic through a European location with strong privacy protections.

**Features:**
- One-command deployment and teardown
- Automatic server configuration via cloud-init
- Privacy-hardened (minimal logging, reduced log retention)
- NAT/masquerading pre-configured
- Firewall locked down (SSH + Tailscale only)
- Cost: ~€3-5/month (~$3.50-5.50 USD)

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Deployment](#deployment)
- [Tailscale Configuration](#tailscale-configuration)
- [Using Your Exit Node](#using-your-exit-node)
- [Verify It's Working](#verify-its-working)
- [Troubleshooting](#troubleshooting)
- [Teardown (Delete Everything)](#teardown-delete-everything)
- [Deploying to Multiple Locations](#deploying-to-multiple-locations)
- [Cost Breakdown](#cost-breakdown)
- [Privacy Features](#privacy-features)
- [Project Structure](#project-structure)
- [Security Notes](#security-notes)
- [Common Issues](#common-issues)
- [Advanced Configuration](#advanced-configuration)
- [Contributing](#contributing)
- [License](#license)

---

## Prerequisites

Before you begin, you'll need:

### 1. Hetzner Cloud Account
1. Sign up at https://www.hetzner.com/cloud
2. Create a new project (e.g., "tailscale-exit-node")
3. Generate an API token:
   - Go to: Security → API Tokens
   - Click "Generate API Token"
   - Permissions: **Read & Write**
   - Save the token securely (you'll need it later)

### 2. SSH Key Pair
Check if you have one:
```bash
ls ~/.ssh/id_*.pub
```

If not, generate one:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### 3. Terraform Installed
**macOS (via Homebrew):**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Other platforms:** https://www.terraform.io/downloads

Verify installation:
```bash
terraform --version
```

### 4. Tailscale Account
Sign up at https://tailscale.com (free tier is sufficient)

---

## Setup Instructions

### Step 1: Clone/Download This Repository

```bash
git clone <your-repo-url>
cd ts-exit-node
```

### Step 2: Create Your Variables File

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

### Step 3: Edit terraform.tfvars

Open `terraform/terraform.tfvars` and add your credentials:

```hcl
# REQUIRED: Your Hetzner Cloud API token
hcloud_token = "your-hetzner-api-token-here"

# REQUIRED: Your SSH public key
ssh_public_key = "ssh-ed25519 AAAAC3Nza... your-email@example.com"

# OPTIONAL: Customize server type (check Hetzner console for available types)
# server_type = "cx23"  # Default works for most, but naming may change
```

**Get your SSH public key:**
```bash
cat ~/.ssh/id_ed25519.pub
# Or if you use RSA:
cat ~/.ssh/id_rsa.pub
```

---

## Deployment

### Step 1: Initialize Terraform

```bash
cd terraform
terraform init
```

**Expected output:** "Terraform has been successfully initialized!"

---

### Step 2: Preview the Deployment

```bash
terraform plan
```

**Review the plan carefully:**
- Should show: `Plan: 4 to add, 0 to change, 0 to destroy`
- Check server name (auto-generated as `tailscale-exit-hel1`)
- Check location (hel1 = Helsinki)
- Verify server type

---

### Step 3: Deploy!

```bash
terraform apply
```

- Type `yes` when prompted
- Deployment takes ~3-5 minutes
- Server will show IP addresses when complete

**Save the output!** You'll see:
- Server IPv4 address
- Server IPv6 address
- SSH command
- Next steps

---

### Step 4: Wait for Cloud-Init (2 minutes)

The server is now booting and configuring itself automatically:
- Installing packages
- Configuring firewall
- Installing Tailscale
- Setting up NAT/masquerading
- Applying privacy hardening

**Optional:** Monitor progress:
```bash
ssh root@<server-ip> "tail -f /var/log/cloud-init-output.log"
```

Press Ctrl+C when you see "Cloud-init v. ... finished"

---

## Tailscale Configuration

### Step 1: SSH Into Server

```bash
ssh root@<server-ip>
```

(Use the IP address from the Terraform output)

---

### Step 2: Authenticate Tailscale

Run this command on the server:

```bash
sudo tailscale up --advertise-exit-node --accept-routes --netfilter-mode=off
```

**You'll see output like:**
```
To authenticate, visit:

https://login.tailscale.com/a/abc123xyz
```

**Copy that URL**, paste it into your browser, and authenticate with your Tailscale account.

**Important:** Do NOT add `--shields-up` - it prevents exit node advertisement!

---

### Step 3: Approve Exit Node in Tailscale Admin

1. Visit: https://login.tailscale.com/admin/machines
2. Find your server: `tailscale-exit-hel1`
3. Click on it to view machine details
4. Under **"Routing Settings"**, find **"Exit Node"**
5. Click **"Edit"** or toggle to enable
6. Set to **"Allowed"**

The exit node is now approved and ready to use!

---

## Using Your Exit Node

### On macOS:
1. Click Tailscale icon in menu bar
2. Click **"Exit node"**
3. Select **"tailscale-exit-hel1"**

### On iOS:
1. Open Tailscale app
2. Tap **"Use exit node"**
3. Select **"tailscale-exit-hel1"**

### On Android/Windows/Linux:
Similar process - look for "Exit node" settings in Tailscale app

---

## Verify It's Working

### Test 1: Check Your IP Location
Visit: https://whatismyip.com

**Should show:**
- Location: Helsinki, Finland
- ISP: Hetzner Online GmbH
- IP: Your server's IP address

### Test 2: Check for DNS Leaks
Visit: https://dnsleaktest.com

Run the extended test - should show Hetzner/Helsinki DNS servers.

---

## Troubleshooting

### Exit Node Not Showing in Client Apps

**Check on server:**
```bash
ssh root@<server-ip>
sudo tailscale status
```

**Should show:**
```
100.x.x.x  tailscale-exit-hel1  ... linux  idle; offers exit node
```

If it just shows `-` instead of `offers exit node`:
1. Re-run the tailscale up command
2. Make sure you didn't use `--shields-up`
3. Check for errors: `sudo journalctl -u tailscaled -n 50`

---

### Can't Connect Through Exit Node

**Check NAT is configured:**
```bash
sudo iptables -t nat -L POSTROUTING -n -v
```

Should show MASQUERADE rule. If not:
```bash
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo netfilter-persistent save
```

**Check IP forwarding:**
```bash
sysctl net.ipv4.ip_forward
```

Should return `1`. If not:
```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

---

### Server Type Not Found Error

If you get "server type cx11 not found" during deployment:

1. Check available server types in Hetzner Console
2. Update `terraform.tfvars`:
   ```hcl
   server_type = "cx23"  # Or whatever is currently available
   ```
3. Run `terraform apply` again

---

## Teardown (Delete Everything)

When you want to remove the exit node and stop billing:

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted.

**What gets deleted:**
- VPS server
- Firewall rules
- SSH key in Hetzner

**What's preserved:**
- Your local Terraform files
- Your terraform.tfvars
- Tailscale configuration (nothing deleted from Tailscale)

**Billing stops immediately** (prorated refund for unused time)

---

## Deploying to Multiple Locations

The server name auto-generates based on location, so you can deploy to multiple regions:

**Example: Deploy to Germany (Falkenstein):**

1. Create a new directory: `terraform-fsn1/`
2. Copy all Terraform files
3. In the new terraform.tfvars, set:
   ```hcl
   location = "fsn1"  # Falkenstein, Germany
   ```
4. Run `terraform apply` from the new directory

You'll now have:
- `tailscale-exit-hel1` (Helsinki)
- `tailscale-exit-fsn1` (Falkenstein)

Both will appear in your Tailscale admin as separate exit nodes!

---

## Cost Breakdown

**Monthly Costs:**
- Hetzner CX23: ~€3-5/month (~$3.50-5.50 USD)
- Tailscale: Free (personal use tier)

**Total: ~$3.50-5.50 USD/month**

**What you get:**
- 1 vCPU (shared)
- 2 GB RAM
- 20 GB NVMe SSD
- 20 TB traffic/month (way more than needed)
- 1 IPv4 + 1 IPv6 address

---

## Privacy Features

This deployment includes privacy hardening:

**Server-side:**
- ✅ IP forwarding logs disabled
- ✅ System log retention: 7 days (vs indefinite)
- ✅ Kernel verbose logging minimized
- ✅ No traffic logging (exit node doesn't log destinations)

**Network:**
- ✅ All traffic encrypted via WireGuard
- ✅ Firewall: Only SSH (22) and Tailscale (41641) open
- ✅ No password authentication (SSH key only)
- ✅ Fail2ban enabled (brute-force protection)

**What can't be hidden:**
- ⚠️ Hetzner sees total bandwidth usage (not content)
- ⚠️ Tailscale control plane knows node is connected

---

## Project Structure

```
.
├── README.md                    # This file
├── CLAUDE.md                    # Documentation for Claude Code
├── terraform/
│   ├── main.tf                  # Infrastructure definition
│   ├── variables.tf             # Variable declarations
│   ├── outputs.tf               # Output definitions
│   ├── cloud-init.yaml          # Server initialization script
│   ├── terraform.tfvars.example # Template for your variables
│   └── terraform.tfvars         # Your secrets (gitignored)
├── .gitignore                   # Protects secrets from git
└── LICENSE                      # MIT License
```

---

## Security Notes

**Files that are NEVER committed to git:**
- `terraform.tfvars` (contains your API token)
- `*.tfstate` (contains resource details and IPs)
- `.terraform/` (provider cache)

These are protected by `.gitignore`.

**SSH Access:**
- Root login via public IP: ✅ Allowed (with SSH key)
- Root login via Tailscale: ❌ Blocked (by default)
- Password authentication: ❌ Disabled

---

## Common Issues

### "Permission denied (publickey)"
- Your SSH key isn't configured correctly
- Make sure you copied the **public** key (ends in `.pub`) to terraform.tfvars
- Try: `ssh-add ~/.ssh/id_ed25519` to add key to SSH agent

### "Server type not found"
- Hetzner changes server type names occasionally
- Check Hetzner Console for current server types
- Update `server_type` in terraform.tfvars

### Exit node not appearing on devices
- Wait 30-60 seconds for Tailscale to sync
- Restart Tailscale app on your device
- Make sure you approved it in admin console
- Verify server shows "offers exit node": `sudo tailscale status`

---

## Advanced Configuration

### Change Server Location

Available Hetzner locations:
- `hel1` - Helsinki, Finland (default)
- `fsn1` - Falkenstein, Germany
- `nbg1` - Nuremberg, Germany

Update `terraform.tfvars`:
```hcl
location = "fsn1"
```

### Enable Automatic Updates

The server already has `unattended-upgrades` enabled for security updates.

To manually update:
```bash
ssh root@<server-ip>
sudo apt update && sudo apt upgrade -y
```

### View Server Logs

```bash
# Cloud-init logs (initial setup)
sudo cat /var/log/cloud-init-output.log

# Tailscale logs
sudo journalctl -u tailscaled -n 100

# Firewall logs
sudo tail -f /var/log/ufw.log

# System logs
sudo journalctl -xe
```

---

## Contributing

Found an issue or have an improvement? Please open an issue or pull request!
