# Backend Migration Guide

## Problem

Your current setup has a circular dependency where the storage account storing the Terraform state is defined in the same configuration that uses it as a backend. This means running `terraform destroy` would delete the backend storage.

## Solution Overview

Separate the backend infrastructure from your application infrastructure into two independent Terraform configurations.

## Step-by-Step Migration

### Step 1: Deploy Backend Infrastructure First

```powershell
# Navigate to the backend directory
cd 02-remote-backend

# Initialize Terraform (this will use local state)
terraform init

# Plan and apply the backend infrastructure
terraform plan
terraform apply
```

This creates:

- Resource group: `terraform-backend-rg`
- Storage account: `farrowmainbackend`
- Blob container: `main`

### Step 2: Migrate Existing State (if needed)

If you have existing state in your main configuration:

```powershell
# Navigate to your main directory
cd ..\01-resource-group

# Backup your existing state
copy terraform.tfstate terraform.tfstate.backup.manual

# Initialize with the new backend (Terraform will prompt to migrate)
terraform init
# Answer 'yes' when prompted to copy existing state to new backend
```

### Step 3: Clean Up Local State References

After successful migration, you can remove the local state file:

```powershell
# Only do this after confirming the remote state is working
rm terraform.tfstate
rm terraform.tfstate.backup  # if exists
```

### Step 4: Test the Setup

```powershell
# In 01-resource-group directory
terraform plan
# Should show your existing resources without proposing to recreate them
```

## Key Benefits of This Approach

1. **Separation of Concerns**: Backend infrastructure is managed separately
2. **Safe Destruction**: You can destroy your main infrastructure without affecting the state storage
3. **Reusability**: The same backend can store state for multiple projects
4. **Security**: Backend infrastructure can have different access controls

## File Structure After Migration

```sh
02-remote-backend/          # Backend infrastructure (uses local state)
├── main.tf                 # Storage account, container, resource group
├── providers.tf            # Provider configuration (no backend block)
└── outputs.tf              # Outputs for backend configuration

01-resource-group/          # Application infrastructure (uses remote state)
├── main.tf                 # Your application resources (storage removed)
├── providers.tf            # Provider with backend configuration
├── variables.tf            # Variables
├── terraform.tfvars        # Variable values
└── outputs.tf              # Application outputs
```

## Important Notes

- The `02-remote-backend` configuration uses LOCAL state (intentionally)
- Only destroy backend infrastructure if you're completely done with all projects using it
- Always backup your state files before major changes
- The backend storage account name must be globally unique in Azure

## Troubleshooting

If you encounter issues:

1. Ensure you're logged into Azure CLI: `az login`
2. Check that the storage account name is globally unique
3. Verify your Azure permissions for creating storage accounts
4. If migration fails, restore from backup and retry.
