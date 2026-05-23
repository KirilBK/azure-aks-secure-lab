# Azure Multi-Tier Container Infrastructure Lab

A hands-on Azure cloud infrastructure project deploying a multi-tier application across Kubernetes, App Service, Container Instances, and serverless Functions — provisioned end-to-end with Terraform, with every secret brokered through Azure Key Vault and managed identities.

![Architecture](./rg-aks-secure-lab.png)

---

## Architecture Overview

This project provisions and configures the following Azure resources, all defined as code with Terraform:

- **Azure Kubernetes Service (AKS)** running a containerized PHP app, with workload identity and the Key Vault CSI driver
- **Azure Container Registry (ACR)** holding the application images
- **Azure Container Instance** running a standalone containerized app
- **2x Azure App Service** (PHP 8.3) on a Linux App Service Plan
- **Azure Functions** (Python) with timer- and HTTP-triggered functions
- **Azure SQL Server + Serverless Database** with auto-pause
- **Azure Key Vault** storing the SQL connection string as a secret
- **User-Assigned Managed Identity** federated to the AKS workload for passwordless secret access
- **Log Analytics + Container Insights** for cluster observability

---

## Infrastructure Components

### Orchestration & Compute

| Resource           | Details                                                              |
| ------------------ | ------------------------------------------------------------------- |
| AKS cluster        | aks-secure-lab — 1 node, Standard\_B2s\_v2, Switzerland North, Free tier control plane |
| Container Instance | app4 — standalone PHP container                                     |
| Cluster networking | Azure CNI with Azure network policy                                 |

### Container Registry

| Resource   | Details                                                       |
| ---------- | ------------------------------------------------------------- |
| ACR        | acrkirilbksecurelab — Basic SKU                               |
| Image pull | AKS authenticates with its kubelet managed identity (AcrPull) |

### Identity & Secrets

| Resource               | Details                                                                          |
| ---------------------- | -------------------------------------------------------------------------------- |
| Key Vault              | kv-kirilbk-securelab — RBAC-authorized, stores `sql-connection-string`           |
| Managed Identity       | id-app1-workload — federated to the AKS service account                          |
| AKS secret access      | Key Vault Secrets Provider (CSI) driver + workload identity — no secret in image |
| App Service / Functions| Key Vault reference app settings, resolved via system-assigned managed identity  |

### Database

| Resource     | Details                                                       |
| ------------ | ------------------------------------------------------------- |
| SQL Server   | sql-kirilbk-securelab — Switzerland North, TLS 1.2 minimum    |
| SQL Database | kirilbkdb — General Purpose Serverless, auto-pause after 60 min |
| Access       | Azure services + operator IP firewall rules                  |

### PaaS & Serverless

| Resource           | Details                                                  |
| ------------------ | -------------------------------------------------------- |
| App Service Plan   | ASP-LINUX — Linux, B1                                     |
| App Service (app2) | app2-kirilbk-securelab — PHP 8.3, no DB                  |
| App Service (app3) | app3-kirilbk-securelab — PHP 8.3, connected to SQL       |
| Function App       | func-kirilbk-securelab — Python 3.11, timer + HTTP triggers |

### Observability

| Resource           | Details                                  |
| ------------------ | ---------------------------------------- |
| Log Analytics      | law-rg-aks-secure-lab                    |
| Container Insights | enabled on AKS via the monitoring agent  |

---

## Application Tiers

### app1 — AKS-hosted PHP App

- Containerized PHP app built via ACR Tasks and deployed to AKS
- Reads its SQL connection string from Key Vault via the CSI driver + workload identity — no credential in the image
- Runs non-root with a read-only root filesystem and dropped Linux capabilities
- Pod-to-pod traffic restricted by a default-deny NetworkPolicy

### app2 — Azure App Service (No DB)

- Stateless PHP app, deployed via ZIP deploy
- Confirms the Key Vault reference resolves through its managed identity

### app3 — Azure App Service (DB Connected)

- PHP app reading from Azure SQL
- The SQL Server PHP driver is installed at container start via a startup script

### app4 — Containerized PHP App (ACI)

- Built from a Dockerfile, pushed to ACR, run as an Azure Container Instance
- Publicly accessible via the container's public IP

### Functions — Python (Timer + HTTP)

- Timer trigger inserts a scheduled row every 3 minutes
- HTTP trigger stores a submitted value, or a default when none is provided
- Reads SQL credentials via a Key Vault reference + managed identity

---

## Key Technical Steps

### Provision the infrastructure

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # set subscription_id, location, your IP, node size
terraform init
terraform apply
```

### Build & push the container image (server-side, no local Docker)

```bash
az acr build --registry <acr-name> --image app1:v1 ./app1
```

### Deploy app1 to AKS

```bash
./scripts/deploy.sh   # builds the image, renders manifests from Terraform outputs, and applies them
```

### App Service deployment

```bash
cd app3 && zip -r ../app3.zip . && cd ..
az webapp deploy -g rg-aks-secure-lab -n <app3-name> --src-path app3.zip --type zip
az webapp config set -g rg-aks-secure-lab -n <app3-name> --startup-file "startup.sh"
```

### Publish the Functions

```bash
cd functions && func azure functionapp publish <func-name> --python && cd ..
```

---

## Security Design Decisions

- **No secrets in code or images** — the SQL connection string lives only in Key Vault
- **AKS workload identity + CSI driver** — pods obtain the secret through a federated managed identity, with nothing stored in the container
- **Key Vault references for PaaS** — App Service and Functions resolve the secret at runtime via managed identity, never holding a plaintext password
- **ACR admin user disabled** — AKS pulls images using its kubelet managed identity
- **Restricted pod security context** — non-root, read-only root filesystem, dropped capabilities, CPU/memory limits
- **In-cluster segmentation** — a default-deny NetworkPolicy means only the ingress path reaches the app
- **Serverless SQL with a closed firewall** — Azure services plus a single operator IP, TLS 1.2 minimum

---

## Lessons Learned

- **Region restricts VM sizes** — `Standard_B2s` isn't offered in Switzerland North on this subscription; `Standard_B2s_v2` is the drop-in replacement
- **A Linux Consumption Function plan can't share a resource group with a Linux App Service plan** — running the Function App on the existing B1 plan avoids the conflict
- **The current `sqlsrv`/`pdo_sqlsrv` PECL packages require PHP 8.3** — both the AKS image and the App Service runtime must target 8.3
- **App Service Linux PHP doesn't ship the SQL Server driver** — it's installed on container start via a startup script
- **AKS with local accounts disabled needs `kubelogin`** before `kubectl` will authenticate against the cluster
- **`func publish` needs a worker-runtime hint** — passing `--python` (or keeping a `local.settings.json`) lets it detect the project language

---

## Resources

- [Azure Kubernetes Service](https://learn.microsoft.com/azure/aks/)
- [AKS workload identity](https://learn.microsoft.com/azure/aks/workload-identity-overview)
- [Azure Key Vault Provider for Secrets Store CSI Driver](https://learn.microsoft.com/azure/aks/csi-secrets-store-driver)
- [Key Vault references for App Service & Functions](https://learn.microsoft.com/azure/app-service/app-service-key-vault-references)
- [Azure Container Instances](https://learn.microsoft.com/azure/container-instances/)
- [Azure Functions Python developer guide](https://learn.microsoft.com/azure/azure-functions/functions-reference-python)
- [Terraform AzureRM provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
