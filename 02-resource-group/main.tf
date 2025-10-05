# ============================================================================
# AZURE INFRASTRUCTURE DEPLOYMENT
# ============================================================================
# This Terraform configuration deploys a secure Azure infrastructure with:
# - Virtual Network with multiple subnets
# - Azure Bastion for secure VM access
# - Azure Firewall with DNAT rules
# - Linux VM running NGINX web server
# ============================================================================

# ----------------------------------------------------------------------------
# RESOURCE GROUP
# ----------------------------------------------------------------------------
# Central container for all Azure resources
# Location: Defined by variable (e.g., East US, West Europe)
# Tags help with cost tracking and resource organization
# ----------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags = {
    Owner       = "InfraTeam"        # Team responsible for this resource
    Environment = "Production"        # Environment type (Dev/Test/Prod)
    Project     = "CoreNetworking"   # Project identifier
  }
}



# ----------------------------------------------------------------------------
# VIRTUAL NETWORK (VNet)
# ----------------------------------------------------------------------------
# Main network container for all subnets
# Address space: Typically 10.1.0.0/16 (65,536 IP addresses)
# All subnets must fall within this address space
# ----------------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space  # Example: ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    Environment = "Production"
  }
}

# ============================================================================
# AZURE BASTION CONFIGURATION
# ============================================================================
# Provides secure RDP/SSH access to VMs without exposing them to public internet
# Eliminates need for jump boxes or VPN connections
# ============================================================================

# ----------------------------------------------------------------------------
# BASTION SUBNET
# ----------------------------------------------------------------------------
# MUST be named "AzureBastionSubnet" (Azure requirement)
# Minimum size: /27 (32 IP addresses)
# Recommended size: /26 or /27 for production
# Address range: 10.1.1.0/27 (10.1.1.0 - 10.1.1.31)
# ----------------------------------------------------------------------------
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"  # Name is mandatory, cannot be changed
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.1.0/27"]       # 32 IP addresses
}

# ----------------------------------------------------------------------------
# BASTION PUBLIC IP
# ----------------------------------------------------------------------------
# Static public IP required for Azure Bastion
# SKU: Standard (required for Bastion)
# Allocation: Static (required for Bastion)
# ----------------------------------------------------------------------------
resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"  # Must be Static for Bastion
  sku                 = "Standard" # Must be Standard for Bastion
}

# ----------------------------------------------------------------------------
# AZURE BASTION HOST
# ----------------------------------------------------------------------------
# Managed service for secure VM access via Azure Portal
# Benefits:
# - No need to expose VMs to public internet
# - No need to manage jump boxes
# - SSL/TLS encrypted connections
# - Integrated with Azure RBAC
# ----------------------------------------------------------------------------
resource "azurerm_bastion_host" "main" {
  name                = "myBastionHost"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                 = "bastionIPConfig"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
  tags = {
    Environment = "Production"
  }
}

# ============================================================================
# AZURE FIREWALL CONFIGURATION
# ============================================================================
# Network security appliance for filtering and inspecting traffic
# Provides DNAT, SNAT, and application/network filtering
# ============================================================================

# ----------------------------------------------------------------------------
# FIREWALL SUBNET
# ----------------------------------------------------------------------------
# MUST be named "AzureFirewallSubnet" (Azure requirement)
# Minimum size: /26 (64 IP addresses)
# Recommended: /26 for production workloads
# Address range: 10.1.2.0/26 (10.1.2.0 - 10.1.2.63)
# ----------------------------------------------------------------------------
resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"  # Name is mandatory
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.2.0/26"]        # 64 IP addresses
}

# ----------------------------------------------------------------------------
# FIREWALL PUBLIC IP
# ----------------------------------------------------------------------------
# Static public IP for Azure Firewall
# This is the IP address users will connect to
# DNAT rules will translate this to internal VM IPs
# ----------------------------------------------------------------------------
resource "azurerm_public_ip" "firewall_pip" {
  name                = "firewall-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"   # Must be Static for Firewall
  sku                 = "Standard"  # Must be Standard for Firewall
}

# ----------------------------------------------------------------------------
# FIREWALL POLICY
# ----------------------------------------------------------------------------
# Container for firewall rules (DNAT, Network, Application rules)
# Policies can be shared across multiple firewalls
# Centralized rule management
# ----------------------------------------------------------------------------
resource "azurerm_firewall_policy" "main" {
  name                = "main-policy"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# ----------------------------------------------------------------------------
# DNAT RULE COLLECTION GROUP
# ----------------------------------------------------------------------------
# Destination Network Address Translation (DNAT) rules
# Translates public IP:port to private IP:port
# Priority: 100 (lower number = higher priority, range: 100-65000)
# Use case: Allow external access to internal NGINX server
# ----------------------------------------------------------------------------
resource "azurerm_firewall_policy_rule_collection_group" "dnat" {
  name               = "dnat-rule-collection-group"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 100  # Lower number = higher priority

  # Collection of DNAT rules for NGINX access
  nat_rule_collection {
    name     = "nginx-dnat-collection"
    priority = 100
    action   = "Dnat"  # Destination NAT action

    # Rule: Allow specific IP to access NGINX via port 4000
    rule {
      name                = "allow-nginx-from-my-ip"
      protocols           = ["TCP"]                              # Protocol type
      source_addresses    = [var.my_public_ip]                   # Your public IP (e.g., "203.0.113.45/32")
      destination_address = azurerm_public_ip.firewall_pip.ip_address  # Firewall public IP
      destination_ports   = ["4000"]                             # External port users connect to
      translated_address  = azurerm_network_interface.vm_nic.private_ip_address  # VM private IP
      translated_port     = "80"                                 # Internal port (NGINX listens on 80)
    }
    # Traffic flow: User -> Firewall_IP:4000 -> VM_Private_IP:80
  }
}

# ----------------------------------------------------------------------------
# AZURE FIREWALL
# ----------------------------------------------------------------------------
# Managed firewall service with built-in high availability
# SKU Tiers:
# - Standard: Basic filtering, threat intelligence
# - Premium: Advanced threat protection, TLS inspection, IDPS
# Threat Intelligence Modes:
# - Off: No threat intelligence
# - Alert: Log threats but allow traffic
# - Deny: Block known malicious traffic
# ----------------------------------------------------------------------------
resource "azurerm_firewall" "main" {
  name                = "myAzureFirewall"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  firewall_policy_id  = azurerm_firewall_policy.main.id

  # IP Configuration linking firewall to subnet and public IP
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }

  sku_name = "AZFW_VNet"  # VNet firewall (also: "AZFW_Hub" for Virtual WAN)
  sku_tier = "Standard"   # Standard tier (also: "Premium" for advanced features)

  threat_intel_mode = "Alert"  # Alert on threats (also: "Off", "Deny")

  tags = {
    Environment = "Production"
    Owner       = "NetworkTeam"
  }
  
  # Ensure DNAT rules are created before firewall
  depends_on = [azurerm_firewall_policy_rule_collection_group.dnat]
}

# ============================================================================
# VIRTUAL MACHINE CONFIGURATION
# ============================================================================
# Linux VM running Ubuntu 22.04 LTS with NGINX web server
# ============================================================================

# ----------------------------------------------------------------------------
# VM SUBNET
# ----------------------------------------------------------------------------
# Dedicated subnet for virtual machines
# Size: /24 (256 IP addresses)
# Address range: 10.1.3.0/24 (10.1.3.0 - 10.1.3.255)
# First 4 IPs reserved by Azure, last IP reserved for broadcast
# Usable IPs: 10.1.3.4 - 10.1.3.254 (251 addresses)
# ----------------------------------------------------------------------------
resource "azurerm_subnet" "vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.3.0/24"]  # 256 IP addresses
}

# ----------------------------------------------------------------------------
# NETWORK INTERFACE CARD (NIC)
# ----------------------------------------------------------------------------
# Virtual network interface for the VM
# IP Allocation: Dynamic (Azure assigns from subnet range)
# Alternative: Static (manually specify IP within subnet range)
# ----------------------------------------------------------------------------
resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"  # Azure assigns IP automatically
    # For static IP: private_ip_address_allocation = "Static"
    #                private_ip_address = "10.1.3.10"
  }
}

# ----------------------------------------------------------------------------
# LINUX VIRTUAL MACHINE
# ----------------------------------------------------------------------------
# Ubuntu 22.04 LTS server for hosting NGINX
# VM Size: Standard_B1s (1 vCPU, 1 GB RAM) - Cost-effective for testing
# Authentication: SSH key-based (password authentication disabled)
# OS Disk: Standard_LRS (Locally Redundant Storage)
# ----------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.vm_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_B1s"  # 1 vCPU, 1 GB RAM
  network_interface_ids           = [azurerm_network_interface.vm_nic.id]
  admin_username                  = var.admin_username
  disable_password_authentication = true  # SSH key only, no password login

  # OS Disk configuration
  os_disk {
    caching              = "ReadWrite"      # Cache mode for better performance
    storage_account_type = "Standard_LRS"   # Standard HDD (also: Premium_LRS, StandardSSD_LRS)
  }

  # SSH Key authentication
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key  # Your SSH public key
  }

  # Ubuntu 22.04 LTS image
  source_image_reference {
    publisher = "Canonical"                        # Image publisher
    offer     = "0001-com-ubuntu-server-jammy"     # Ubuntu 22.04 (Jammy Jellyfish)
    sku       = "22_04-lts"                        # LTS version
    version   = "latest"                           # Always use latest patch
  }

  # Ensure NIC is created before VM
  depends_on = [azurerm_network_interface.vm_nic]
}