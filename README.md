# Azure Infrastructure as Code - Secure Multi-Tier Web Application

## Overview

This Terraform project provisions a secure, production-ready infrastructure for hosting a multi-tier web application in Azure. The infrastructure supports separate CDE (development) and Production environments with complete network isolation and least-privilege access controls.

## Architecture

### High-Level Design

```
┌─────────────────────────────────────────────────────────────┐
│  Internet                                                    │
│                                                               │
│  ┌─────────────┐                                             │
│  │  Frontend   │  (Public, HTTPS only)                       │
│  │  App Service│                                             │
│  └──────┬──────┘                                             │
│         │                                                     │
├─────────┼─────────────────────────────────────────────────────┤
│  VNet   │                                                     │
│         │                                                     │
│  ┌──────▼──────┐     ┌──────────────┐                       │
│  │  App Subnet │     │ Private EP   │                       │
│  │             │     │   Subnet     │                       │
│  │  ┌────────┐ │     │              │                       │
│  │  │Backend │ │     │  ┌─────────┐ │                       │
│  │  │App Svc │─┼─────┼─►│SQL DB   │ │ (Private Endpoint)   │
│  │  └───┬────┘ │     │  └─────────┘ │                       │
│  │      │      │     │              │                       │
│  │      ├──────┼─────┼─►┌─────────┐ │                       │
│  │      │      │     │  │ Storage │ │ (Private Endpoint)   │
│  │      │      │     │  └─────────┘ │                       │
│  │      │      │     │              │                       │
│  │      └──────┼─────┼─►┌─────────┐ │                       │
│  │             │     │  │Key Vault│ │ (Private Endpoint)   │
│  └─────────────┘     │  └─────────┘ │                       │
│                      └──────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

### Network Architecture

- **VNet**: Single-purpose virtual network (`10.1.0.0/16`)
- **Subnets**:
  - **Web** (`10.1.1.0/24`): Reserved for future use
  - **App** (`10.1.2.0/24`): App Service VNet integration with service endpoints
  - **DB** (`10.1.3.0/24`): Reserved (not used - SQL uses private endpoints)
  - **Private Endpoint** (`10.1.4.0/24`): Hosts all private endpoints

### Security Features

#### 1. **Network Security**
- ✅ All PaaS services use **private endpoints** (SQL, Storage, Key Vault, Backend App)
- ✅ **Public network access disabled** on all data services
- ✅ Frontend app is internet-facing, backend is private-only
- ✅ VNet integration forces all outbound traffic through VNet
- ✅ Service endpoints enabled on app subnet for defense-in-depth
- ✅ Network Security Groups (NSGs) on all subnets
- ✅ Private DNS zones for private endpoint name resolution

#### 2. **Identity & Access Management (Least Privilege)**
- ✅ **System-assigned managed identities** for all App Services
- ✅ **No connection strings or passwords** in app configuration
- ✅ **Azure RBAC** for all resource access:
  - Backend app: Storage Blob Data Contributor (read/write)
  - Frontend app: Storage Blob Data Reader (read-only)
  - Both apps: Key Vault Secrets User (read secrets)
  - SQL: Azure AD authentication with contained database users
- ✅ Key Vault uses **RBAC authorization** (not access policies)

#### 3. **Data Protection**
- ✅ **TLS 1.2 minimum** on all services
- ✅ **HTTPS only** enforced on App Services
- ✅ **Purge protection** enabled on Key Vault
- ✅ **Soft delete** enabled on Storage (7 days) and Key Vault
- ✅ **Blob versioning** enabled for data recovery
- ✅ SQL **auditing** enabled and sent to Log Analytics
- ✅ Secrets stored in Key Vault (SQL passwords, connection strings)

#### 4. **Monitoring & Compliance**
- ✅ **Log Analytics Workspace** for centralized logging
- ✅ **Application Insights** for app telemetry
- ✅ **Diagnostic settings** on SQL, Storage, and Key Vault
- ✅ All logs retained for 30 days (configurable)

## Compute Platform Choice: Azure App Service (PaaS)

**Rationale**: App Service was selected over VMs for the following reasons:

1. **Reduced Operational Overhead**: No OS patching, no infrastructure management
2. **Built-in Security**: Automatic security updates, managed certificates, easy HTTPS enforcement
3. **Native Azure Integration**: Seamless VNet integration, managed identity support, Key Vault references
4. **Cost-Effective**: Pay only for compute time, auto-scaling capabilities
5. **Developer Productivity**: Easy deployment pipelines, staging slots, continuous deployment support
6. **Compliance**: Built-in compliance features (SOC, PCI DSS, ISO certifications)

For this small web application scenario, App Service provides the optimal balance of security, manageability, and cost.

## Environment Separation Strategy

The infrastructure supports multiple environments through:

1. **Separate Resource Groups**: Each environment gets its own RG
2. **Separate State Files**: Backend state stored in environment-specific containers
3. **Environment-Specific Variables**: Different configs per environment via `variables.tf`
4. **Naming Conventions**: Resources tagged with environment suffix (e.g., `-cde`, `-prod`)
5. **Isolated Networks**: Each environment has its own VNet (no peering required for this use case)

**Key Differences Between Environments**:
| Aspect | CDE | Production |
|--------|-----|------------|
| Resource Group | `rg-myapp-cde` | `rg-myapp-prod` |
| App Service SKU | S1 (Standard) | P1v2 (Premium) |
| SQL SKU | S0 | S1 (or higher) |
| Retention | 7 days | 30+ days |
| Monitoring | Basic | Enhanced |

## Prerequisites

Before deploying this infrastructure, ensure you have:

1. **Azure CLI** installed and configured (`az --version`)
2. **Terraform** >= 1.5.0 installed (`terraform --version`)
3. **Azure Subscription** with appropriate permissions
4. **Service Principal** or user account with:
   - Owner or Contributor + User Access Administrator roles
   - Ability to create Azure AD applications (for managed identities)
5. **Backend Storage** for Terraform state (run `bootstrap_backend.sh`)

## Setup Instructions

### 1. Clone and Navigate

```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Bootstrap Backend Storage

The Terraform state needs to be stored remotely in Azure Storage. Run the bootstrap script:

```bash
# Make script executable
chmod +x bootstrap_backend.sh

# Run bootstrap (creates storage account for state)
./bootstrap_backend.sh

# Note the output values - you'll need these for backend configuration
```

### 3. Configure Backend State

Create a `terraform.tfvars` file in the environment directory:

**For CDE Environment** (`terraform/envs/cde/terraform.tfvars`):

```hcl
subscription_id          = "your-subscription-id"
backend_rg               = "rg-terraform-state"
backend_storage_account  = "sttfstate<unique>"
backend_container        = "tfstate"
admin_ad_object_id       = "your-azure-ad-object-id"  # Get with: az ad signed-in-user show --query id -o tsv
```

**For Production** (`terraform/envs/prod/terraform.tfvars`):

```hcl
subscription_id          = "your-subscription-id"
backend_rg               = "rg-terraform-state"
backend_storage_account  = "sttfstate<unique>"
backend_container        = "tfstate"
admin_ad_object_id       = "your-azure-ad-object-id"
```

### 4. Initialize Terraform

```bash
# Navigate to environment directory
cd terraform/envs/cde

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

### 5. Post-Deployment Configuration

After Terraform completes, you need to configure SQL Database managed identity access:

```bash
# 1. Get backend app name
BACKEND_APP=$(terraform output -raw backend_url | cut -d'.' -f1)

# 2. Get SQL Server FQDN
SQL_SERVER=$(terraform output -raw sql_server_fqdn)

# 3. Connect to SQL Database using Azure AD authentication
az login
sqlcmd -S $SQL_SERVER -d appdb -G

# 4. In SQL prompt, create managed identity user
CREATE USER [$BACKEND_APP] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [$BACKEND_APP];
ALTER ROLE db_datawriter ADD MEMBER [$BACKEND_APP];
GO
```

Alternatively, use the provided script in `terraform/modules/sql/create_mi_user.sql`.

### 6. Verify Deployment

Test the infrastructure:

```bash
# Get frontend URL
terraform output frontend_url

# Test connectivity (should return 404 or app-specific response since no app deployed yet)
curl -I https://$(terraform output -raw frontend_url)

# Verify private endpoint resolution
nslookup $(terraform output -raw sql_server_fqdn)
# Should resolve to private IP (10.1.4.x)
```

## Project Structure

```
.
├── terraform/
│   ├── envs/
│   │   ├── cde/
│   │   │   ├── backend.tf          # Backend state configuration
│   │   │   ├── main.tf             # Environment orchestration
│   │   │   ├── provider.tf         # Azure provider config
│   │   │   ├── variables.tf        # Environment variables
│   │   │   └── terraform.tfvars    # Variable values (not in git)
│   │   └── prod/
│   │       └── (same structure)
│   └── modules/
│       ├── network/                 # VNet, subnets, NSGs, DNS zones
│       ├── appservice/              # App Service plans and apps
│       ├── sql/                     # Azure SQL Database
│       ├── storage/                 # Storage Account and RBAC
│       ├── keyvault/                # Key Vault and secrets
│       └── monitoring/              # Log Analytics and App Insights
├── .github/
│   └── workflows/
│       └── terraform-deploy.yml     # CI/CD pipeline
├── bootstrap_backend.sh             # State storage setup
└── README.md
```

## Deploying Application Code

Once infrastructure is deployed, deploy your application:

```bash
# For Node.js app
cd your-app-directory
zip -r app.zip .
az webapp deployment source config-zip \
  --resource-group rg-myapp-cde \
  --name $(terraform output -raw backend_url | cut -d'.' -f1) \
  --src app.zip

# Or use GitHub Actions, Azure DevOps, etc.
```

## Managing Secrets

All secrets are stored in Key Vault and referenced by App Services using managed identities:

```bash
# Add a new secret
az keyvault secret set \
  --vault-name kv-cde-myapp \
  --name "api-key" \
  --value "your-secret-value"

# Reference in App Service app settings (Terraform or manually)
APP_SETTING="@Microsoft.KeyVault(SecretUri=https://kv-cde-myapp.vault.azure.net/secrets/api-key/)"
```

## Destroying Infrastructure

To tear down an environment:

```bash
cd terraform/envs/cde
terraform destroy

# Confirm by typing 'yes'
```

**Note**: Due to purge protection on Key Vault, you may need to manually purge it after destroy:

```bash
az keyvault purge --name kv-cde-myapp
```

## Security Considerations

### Implemented Security Controls

✅ **Network Isolation**: All data services behind private endpoints
✅ **Zero Trust**: No implicit trust, all access via managed identities
✅ **Least Privilege**: RBAC roles grant minimum required permissions
✅ **Encryption**: TLS 1.2+ for all traffic, encryption at rest by default
✅ **Secrets Management**: No secrets in code or app config
✅ **Auditing**: All access logged to Log Analytics
✅ **Compliance**: Built-in Azure compliance features utilized

### Additional Recommendations for Production

Consider implementing these additional security measures:

- [ ] **Azure DDoS Protection** on VNet
- [ ] **Azure Firewall** for centralized egress filtering
- [ ] **Application Gateway with WAF** for frontend (not required by assignment)
- [ ] **Azure Policy** for governance and compliance
- [ ] **Azure Defender** for advanced threat protection
- [ ] **Conditional Access** policies for admin access
- [ ] **Privileged Identity Management (PIM)** for JIT admin access
- [ ] **Network Watcher** for traffic analysis
- [ ] **Azure Backup** for SQL Database
- [ ] **Geo-redundant storage (GRS)** for production data

## Troubleshooting

### Common Issues

**Issue**: Private endpoint DNS not resolving

```bash
# Check private DNS zone configuration
az network private-dns link vnet list \
  --resource-group rg-myapp-cde \
  --zone-name privatelink.database.windows.net

# Ensure VNet is linked to private DNS zones
```

**Issue**: App Service can't connect to SQL

```bash
# Verify managed identity is created
az webapp identity show \
  --resource-group rg-myapp-cde \
  --name backend-rg-myapp-cde-0

# Verify SQL user was created (run create_mi_user.sql)
# Check if VNet integration is working
az webapp vnet-integration list \
  --resource-group rg-myapp-cde \
  --name backend-rg-myapp-cde-0
```

**Issue**: Terraform errors about Key Vault permissions

```bash
# Ensure your service principal has Key Vault Secrets Officer role
az role assignment create \
  --assignee <your-sp-object-id> \
  --role "Key Vault Secrets Officer" \
  --scope /subscriptions/<sub-id>/resourceGroups/rg-myapp-cde/providers/Microsoft.KeyVault/vaults/kv-cde-myapp
```

## Issues Encountered During Development

### 1. Circular Dependency Between Modules

**Problem**: App Service needs Key Vault references, but Key Vault needs App Service principal IDs for RBAC.

**Solution**: Used Terraform `depends_on` to establish explicit dependency chain:

1. Create App Service (get principal IDs)
2. Create other resources (SQL, Storage)
3. Create Key Vault with RBAC assignments
4. Update App Service configuration with Key Vault references

### 2. Private Endpoint DNS Resolution

**Problem**: Private endpoints weren't resolving to private IPs from within VNet.

**Solution**: Created private DNS zones in network module and linked them to VNet. Each private endpoint now uses DNS zone groups for automatic DNS registration.

### 3. SQL Managed Identity Authentication

**Problem**: Can't create SQL users via Terraform because it requires Azure AD authentication.

**Solution**: Provided post-deployment SQL script (`create_mi_user.sql`) that must be run manually after infrastructure deployment. This is a known limitation of Terraform with Azure SQL + managed identities.

### 4. Key Vault RBAC vs Access Policies

**Problem**: Initial implementation used access policies, which are less granular.

**Solution**: Migrated to RBAC authorization model (`enable_rbac_authorization = true`) for finer-grained access control using Azure built-in roles.

### 5. Storage Account Public Access

**Problem**: Storage account needed to be accessible from VNet but secure from internet.

**Solution**: Disabled public access (`public_network_access_enabled = false`), created private endpoint, and used RBAC to grant App Service managed identities blob access.

### 6. Backend App Accessibility

**Problem**: Backend app should only be accessible from frontend, not from internet.

**Solution**: Created private endpoint for backend App Service. Frontend accesses backend via private endpoint hostname within VNet.

## Questions That Arose

1. **Q**: Should frontend have direct SQL access?
   **A**: No - frontend should only call backend API. Backend app is the only one with SQL access (least privilege).

2. **Q**: Use access policies or RBAC for Key Vault?
   **A**: RBAC is the modern, recommended approach. More flexible and integrates better with Azure AD governance.

3. **Q**: Should we use user-assigned or system-assigned managed identities?
   **A**: System-assigned for this use case (simpler, automatically lifecycle-managed with app). User-assigned is better when sharing identity across resources.

4. **Q**: How to handle SQL schema migrations?
   **A**: Not covered by IaC - use tools like Flyway, Liquibase, or EF Migrations in application deployment pipeline.

5. **Q**: What about disaster recovery?
   **A**: For production, consider geo-redundant storage, SQL geo-replication, and Traffic Manager. Not implemented here due to cost and scope.

## CI/CD Pipeline

A GitHub Actions workflow is included (`.github/workflows/terraform-deploy.yml`) for automated deployments. Configure these secrets in GitHub:

- `AZURE_CREDENTIALS`: Service principal JSON
- `TF_VAR_admin_ad_object_id`: SQL admin object ID
- `TF_VAR_subscription_id`: Azure subscription ID

## Cost Estimate

Approximate monthly costs per environment (East US region):

| Resource | SKU | Monthly Cost (USD) |
|----------|-----|-------------------|
| App Service Plan | S1 | ~$75 |
| SQL Database | S0 | ~$15 |
| Storage Account | LRS, Standard | ~$5 |
| Key Vault | Standard | ~$3 |
| Log Analytics | 5GB/month | ~$10 |
| Private Endpoints | 3 endpoints | ~$15 |
| **Total** | | **~$123/month** |

Production environment with P1v2 App Service: ~$200-250/month

## Support and Contact

For questions or issues:
- Consult with development team for questions or inquiries