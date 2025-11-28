# Product Requirements Document: Swiss Tailscale Exit Node Infrastructure

## 1. Executive Summary

### 1.1 Purpose
Develop automated infrastructure-as-code to provision and configure a privacy-focused Tailscale exit node hosted in Switzerland, enabling secure access to the internet from alternative geographic locations.

### 1.2 Goals
- Deploy a VPS in Switzerland with strong privacy protections
- Automatically configure the VPS as a Tailscale exit node
- Enable one-command deployment and teardown
- Maintain infrastructure as reproducible, version-controlled code

### 1.3 Non-Goals
- Multi-region deployment (single Swiss location only)
- High availability or load balancing
- VPN service for multiple users (personal use only)
- Ongoing configuration management beyond initial setup

---

## 2. Background & Context

### 2.1 Problem Statement
User requires ability to route internet traffic through a European location (Switzerland) to ensure continued access to information in case of increasing content restrictions in the United States.

### 2.2 Why Switzerland
- Strong privacy laws and constitutional protections
- Not part of Five Eyes intelligence sharing
- Stable political environment
- Banking secrecy traditions extended to digital data
- Located in Europe but not EU member

### 2.3 Why Tailscale
- WireGuard-based VPN with zero-configuration mesh networking
- Exit node functionality allows routing all traffic through specific nodes
- Encrypted peer-to-peer connections
- No central VPN server to compromise
- Free tier sufficient for personal use

---

## 3. Technical Requirements

### 3.1 Infrastructure Provider

**Primary Option: Hetzner (Finland)**
- Location: Helsinki datacenter (hel1)
- Rationale: Strong GDPR protections, excellent Terraform support, best value
- Server Type: CX11 (€3.29/month)
  - 1 vCPU (AMD/Intel shared)
  - 2 GB RAM
  - 20 GB NVMe SSD
  - 20 TB traffic/month
  - 1 IPv4 + 1 IPv6 address

**Alternative Option: Infomaniak (Switzerland)**
- Location: Geneva or Zurich
- Use if Swiss jurisdiction is strict requirement
- Similar specs, slightly higher cost (~CHF 5-8/month)

### 3.2 Operating System
- **Distribution**: Ubuntu 24.04 LTS
- **Rationale**: 
  - Long-term support until 2029
  - Excellent Tailscale package support
  - Well-documented cloud-init compatibility
  - Familiar tooling

### 3.3 Infrastructure as Code Tool
- **Tool**: Terraform
- **Provider**: Official Hetzner Cloud provider (hetznercloud/hcloud)
- **Version**: ~> 1.45 or later
- **State Storage**: Local terraform.tfstate (can migrate to remote later)

### 3.4 Initial Configuration Method
- **Tool**: Cloud-init
- **Rationale**: 
  - Native support in Hetzner/Infomaniak
  - Runs once at boot (appropriate for immutable infrastructure)
  - No additional tools required
  - Simpler than Ansible for single-server setup

---

## 4. Functional Requirements

### 4.1 Infrastructure Provisioning

**FR-1: VPS Creation**
- System SHALL create a VPS instance using Terraform
- System SHALL use the CX11 server type (or equivalent)
- System SHALL deploy to Helsinki (hel1) location
- System SHALL use Ubuntu 24.04 LTS image

**FR-2: SSH Access**
- System SHALL configure SSH key-based authentication only
- System SHALL disable password authentication
- System SHALL disable root login
- System SHALL create non-root sudo user for administration

**FR-3: Network Configuration**
- System SHALL assign public IPv4 address
- System SHALL assign public IPv6 address
- System SHALL configure firewall to allow SSH (port 22)
- System SHALL configure firewall to allow Tailscale (UDP port 41641)
- System SHALL enable IP forwarding for exit node functionality

**FR-4: Resource Outputs**
- System SHALL output server IPv4 address
- System SHALL output server IPv6 address
- System SHALL output server name/ID

### 4.2 Tailscale Configuration

**FR-5: Tailscale Installation**
- System SHALL install latest stable Tailscale package
- System SHALL enable tailscaled service at boot
- System SHALL configure system to allow IP forwarding

**FR-6: Exit Node Setup**
- System SHALL advertise the node as an exit node
- System SHALL accept subnet routes
- System SHALL require manual authentication on first run (security best practice)

**FR-7: Firewall Configuration**
- System SHALL install and enable ufw (Uncomplicated Firewall)
- System SHALL default deny incoming connections
- System SHALL default allow outgoing connections
- System SHALL allow SSH from anywhere
- System SHALL allow Tailscale UDP traffic

### 4.3 Security Hardening

**FR-8: System Security**
- System SHALL enable automatic security updates
- System SHALL install fail2ban for SSH brute-force protection
- System SHALL configure kernel parameters for IP forwarding
- System SHALL disable unnecessary services

**FR-9: Access Control**
- System SHALL only accept SSH connections with key authentication
- System SHALL configure sudo to require password for sudo user
- System SHALL set up basic intrusion prevention

### 4.4 Automation & Reproducibility

**FR-10: Declarative Infrastructure**
- All infrastructure SHALL be defined in Terraform configuration files
- Configuration SHALL be idempotent (safe to run multiple times)
- Infrastructure SHALL be destroyable and recreatable

**FR-11: Version Control Ready**
- All code SHALL be in files suitable for git version control
- Secrets SHALL NOT be hardcoded in configuration files
- Secrets SHALL be passed via environment variables or Terraform variables

**FR-12: Documentation**
- System SHALL include README with setup instructions
- System SHALL include instructions for Tailscale authentication
- System SHALL include instructions for enabling exit node in Tailscale admin

---

## 5. Technical Design

### 5.1 Project Structure

```
tailscale-exit-node/
├── README.md                 # Setup and usage instructions
├── terraform/
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── terraform.tfvars     # Variable values (gitignored)
│   └── cloud-init.yaml      # Cloud-init configuration
└── .gitignore               # Ignore secrets and state files
```

### 5.2 Terraform Configuration Components

**variables.tf**
- `hcloud_token` (sensitive): Hetzner API token
- `ssh_public_key`: Public SSH key for access
- `server_name`: Name for the VPS (default: "tailscale-exit-node")
- `server_type`: Server size (default: "cx11")
- `location`: Datacenter location (default: "hel1")
- `image`: OS image (default: "ubuntu-24.04")

**main.tf**
- Provider configuration (hcloud)
- SSH key resource
- Server resource with cloud-init
- Firewall rules resource

**outputs.tf**
- Server IPv4 address
- Server IPv6 address
- Server ID
- Next steps instructions

**cloud-init.yaml**
- System updates and package installation
- User creation and SSH configuration
- Tailscale installation
- IP forwarding configuration
- Firewall setup
- Service enablement

### 5.3 Cloud-Init Configuration Stages

**Stage 1: System Preparation**
- Update package cache
- Upgrade existing packages
- Install required packages (curl, ufw, fail2ban)

**Stage 2: User & Security**
- Create admin user with SSH key
- Disable root login
- Disable password authentication
- Configure sudo access

**Stage 3: Network Configuration**
- Enable IP forwarding in sysctl
- Configure ufw firewall rules
- Enable fail2ban

**Stage 4: Tailscale Installation**
- Download and run Tailscale install script
- Enable tailscaled service
- Configure but don't authenticate (requires manual step)

---

## 6. Non-Functional Requirements

### 6.1 Performance
- NFR-1: VPS SHALL have sufficient bandwidth for personal browsing (20TB/month exceeds requirements)
- NFR-2: Deployment SHALL complete in under 5 minutes
- NFR-3: Boot time SHALL be under 60 seconds

### 6.2 Reliability
- NFR-4: Infrastructure SHALL be reproducible from code
- NFR-5: Server SHALL survive reboots with all services starting automatically
- NFR-6: System SHALL handle network interruptions gracefully

### 6.3 Security
- NFR-7: All traffic through exit node SHALL be encrypted via WireGuard
- NFR-8: Server SHALL have minimal attack surface (only SSH and Tailscale ports open)
- NFR-9: System SHALL receive automatic security updates

### 6.4 Cost
- NFR-10: Monthly hosting cost SHALL NOT exceed $5 USD
- NFR-11: Solution SHALL use free tier of Tailscale

### 6.5 Maintainability
- NFR-12: Infrastructure SHALL be manageable by single person
- NFR-13: Code SHALL be readable and well-commented
- NFR-14: Updates SHALL be applicable via Terraform

---

## 7. User Workflows

### 7.1 Initial Setup Workflow

1. **Prerequisites Setup**
   - User creates Hetzner account
   - User generates Hetzner API token
   - User generates SSH key pair (if not exists)
   - User installs Terraform locally

2. **Configuration**
   - User clones/downloads infrastructure code
   - User creates `terraform.tfvars` with their values
   - User reviews configuration

3. **Deployment**
   - User runs `terraform init`
   - User runs `terraform plan` (review changes)
   - User runs `terraform apply`
   - System provisions VPS and configures it

4. **Tailscale Authentication**
   - User SSHs into server
   - User runs Tailscale authentication command
   - User approves exit node in Tailscale admin console

5. **Verification**
   - User enables exit node on client device
   - User verifies IP address shows as Finland
   - User tests internet connectivity

### 7.2 Ongoing Usage Workflow

1. **Connect via Exit Node**
   - User opens Tailscale on device
   - User selects the exit node
   - Traffic routes through Swiss/Finnish server

2. **Disconnect**
   - User disables exit node in Tailscale
   - Traffic returns to normal routing

### 7.3 Maintenance Workflow

1. **Updates**
   - Server automatically updates packages
   - User can SSH in for manual updates if needed
   - For major changes, user updates Terraform and re-applies

2. **Monitoring**
   - User can SSH in to check logs
   - Tailscale admin console shows connectivity
   - Hetzner console shows resource usage

3. **Teardown**
   - User runs `terraform destroy`
   - All resources are deleted
   - User is no longer billed

---

## 8. Constraints & Assumptions

### 8.1 Constraints
- CONSTRAINT-1: Must use providers with public APIs (Hetzner, Infomaniak)
- CONSTRAINT-2: Budget limited to ~$5/month
- CONSTRAINT-3: Single server deployment (no redundancy)
- CONSTRAINT-4: Manual Tailscale authentication required (cannot automate auth keys in repo)

### 8.2 Assumptions
- ASSUMPTION-1: User has basic command-line familiarity
- ASSUMPTION-2: User has Tailscale account already
- ASSUMPTION-3: User is comfortable with SSH
- ASSUMPTION-4: User's local machine can run Terraform
- ASSUMPTION-5: User has credit card or PayPal for hosting payment

---

## 9. Security Considerations

### 9.1 Secrets Management
- API tokens SHALL NOT be committed to version control
- SSH private keys SHALL remain on user's machine only
- Use `.gitignore` to exclude `terraform.tfvars` and `.tfstate` files

### 9.2 Access Control
- Only user's SSH key SHALL have access to server
- Tailscale authentication provides additional layer
- No public services exposed beyond SSH and Tailscale

### 9.3 Data Privacy
- No logging of traffic on exit node
- No persistent storage of user data
- Exit node operator (user) cannot see encrypted Tailscale traffic content

### 9.4 Threat Model
- **Protected Against**: 
  - Geographic content restrictions
  - ISP-level monitoring of browsing
  - Basic network attacks
  
- **NOT Protected Against**: 
  - Targeted nation-state attacks
  - Compromise of user's device
  - Compromise of Tailscale infrastructure
  - Legal requests to hosting provider (logs minimal anyway)

---

## 10. Future Enhancements (Out of Scope)

### 10.1 Possible V2 Features
- Multi-region deployment with automatic failover
- Remote Terraform state storage (S3, Terraform Cloud)
- Monitoring and alerting (Prometheus, Grafana)
- Automated backup and disaster recovery
- IPv6-only deployment option
- Container-based deployment (Docker)

### 10.2 Advanced Configurations
- Pi-hole integration for DNS-level ad blocking
- WireGuard direct access (bypass Tailscale)
- Multiple exit nodes for load distribution
- Automated rotation of nodes for privacy

---

## 11. Success Criteria

### 11.1 Deployment Success
- ✅ User can run `terraform apply` successfully
- ✅ VPS is created and accessible via SSH
- ✅ Tailscale is installed and running
- ✅ Exit node appears in Tailscale admin console

### 11.2 Functional Success
- ✅ User can enable exit node on client device
- ✅ IP address check shows Finnish/Swiss location
- ✅ Web browsing works normally through exit node
- ✅ Connection is stable for extended periods

### 11.3 Reproducibility Success
- ✅ Running `terraform destroy` removes all resources
- ✅ Running `terraform apply` again recreates identical setup
- ✅ Another user can deploy using same code with their credentials

---

## 12. Acceptance Criteria

**AC-1: Infrastructure Provisioning**
- GIVEN user has Terraform and Hetzner credentials
- WHEN user runs `terraform apply`
- THEN VPS is created within 5 minutes with correct specifications

**AC-2: Tailscale Configuration**
- GIVEN VPS is provisioned
- WHEN user SSHs to server
- THEN Tailscale is installed, service is running, and ready for authentication

**AC-3: Exit Node Functionality**
- GIVEN Tailscale is authenticated and approved
- WHEN user enables exit node on client
- THEN all traffic routes through the VPS

**AC-4: Security Hardening**
- GIVEN server is deployed
- WHEN user attempts password SSH login
- THEN login is denied (key-only access)

**AC-5: Firewall Configuration**
- GIVEN server is deployed
- WHEN user checks firewall status
- THEN only SSH (22) and Tailscale (41641) ports are open

**AC-6: Code Quality**
- GIVEN infrastructure code exists
- WHEN reviewer examines code
- THEN code is well-commented, organized, and follows Terraform best practices

**AC-7: Documentation**
- GIVEN README exists
- WHEN new user reads documentation
- THEN user can complete deployment without external help

---

## 13. Appendices

### 13.1 Glossary
- **Exit Node**: Tailscale node that routes traffic to the public internet
- **Cloud-init**: Industry-standard method for cloud instance initialization
- **IaC**: Infrastructure as Code
- **VPS**: Virtual Private Server
- **WireGuard**: Modern VPN protocol used by Tailscale

### 13.2 References
- Tailscale Exit Nodes: https://tailscale.com/kb/1103/exit-nodes
- Terraform Hetzner Provider: https://registry.terraform.io/providers/hetznercloud/hcloud
- Cloud-init Documentation: https://cloudinit.readthedocs.io/
- Hetzner Cloud Documentation: https://docs.hetzner.com/cloud/

### 13.3 Related Specifications
- WireGuard Protocol: https://www.wireguard.com/protocol/
- Ubuntu Cloud Images: https://cloud-images.ubuntu.com/

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-11-28 | Initial | Complete PRD for Tailscale exit node infrastructure |

---

## Approval

This PRD is ready for implementation via Claude Code in VS Code.

**Recommended Implementation Order:**
1. Set up Terraform project structure
2. Implement basic VPS provisioning
3. Add cloud-init configuration
4. Add firewall rules
5. Add outputs and documentation
6. Test deployment end-to-end
7. Document manual Tailscale authentication steps