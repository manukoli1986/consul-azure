# Terraform Azure Setup
This repository contains Terraform code to deploy resources in Azure. Follow the instructions below to get started.
## Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) installed on your local machine
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed on your local machine
- An Azure subscription
- setup Pub and Priv Key on local to connect Consul VMs

## Setup
1. Clone this repository to your local machine:
```
cd consul
```
2. Login to Azure using the Azure CLI:
```
az login
```
3. Initialize Terraform:
```
terraform init
```
## Usage
1. Review the Terraform plan:
```
terraform plan 
```
2. Apply the Terraform plan:
```
terraform apply 

Outputs:

consul_servers = [
  "20.163.166.170",
  "4.227.229.157",
]
```

3. Destroy the resources when you are finished:
```
terraform destroy 
```

## Connect to all 3 VMs and restart the Consul services 
```
ssh ecomadm@20.163.166.170 sudo systemctl restart consul
ssh ecomadm@20.163.166.170 consul members

```
