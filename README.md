# Azure Secure Infrastructure with Terraform

![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![NGINX](https://img.shields.io/badge/NGINX-009639?style=for-the-badge&logo=nginx&logoColor=white)

## 📋 Overview

This Terraform project deploys a secure, production-ready Azure infrastructure with the following components:

- **Virtual Network** with multiple subnets
- **Azure Bastion** for secure VM access
- **Azure Firewall** with DNAT rules
- **Linux VM** running Ubuntu 22.04 LTS with NGINX

## 🏗️ Architecture

┌─────────────────────────────────────────────────────────────┐
│ Azure Virtual Network │
│ (10.1.0.0/16) │
├─────────────────────────────────────────────────────────────┤
│ │
│ ┌──────────────────┐ ┌──────────────────┐ ┌───────────┐ │
│ │ AzureBastionSubnet│ │AzureFirewallSubnet│ │ VM Subnet │ │
│ │ 10.1.1.0/27 │ │ 10.1.2.0/26 │ │10.1.3.0/24│ │
│ │ │ │ │ │ │ │
│ │ Azure Bastion │ │ Azure Firewall │ │ NGINX VM │ │
│ │ (Secure Access) │ │ (DNAT Rules) │ │ (Private) │ │
│ └──────────────────┘ └──────────────────┘ └───────────┘ │
│ │
└─────────────────────────────────────────────────────────────┘
│
▼
Internet (Your IP Only)

## ✨ Features

### 🔒 Security

- **Azure Bastion**: Secure RDP/SSH access without exposing VMs to the internet
- **Azure Firewall**: Network-level protection with DNAT rules
- **SSH Key Authentication**: Password authentication disabled
- **IP Whitelisting**: Only your IP can access NGINX server

### 🌐 Networking

- **Virtual Network**: Isolated network environment (10.1.0.0/16)
- **Multiple Subnets**: Segmented network for different services
- **DNAT Rules**: Port forwarding from Firewall (port 4000) to VM (port 80)

### 💻 Compute

- **Ubuntu 22.04 LTS**: Long-term support Linux distribution
- **NGINX Web Server**: High-performance web server
- **Cost-Optimized**: Standard_B1s VM size for testing/development

## 📁 Project Structure

.
├── main.tf # Main Terraform configuration
├── variables.tf # Variable definitions
├── terraform.tfvars # Variable values (DO NOT commit sensitive data)
├── outputs.tf # Output definitions
├── README.md # This file
└── .gitignore # Git ignore file
