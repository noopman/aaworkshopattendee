# Module 6: Microservices Architecture
#----------------------------------------------------------------------------------------------------------------------
# Exercise 2

# ----------------------------------------------------------------------------------------------------------------------
# Step 1: Create a Storage Account and Update the Container App Environment

# 1.1 Create the storage account

# lowercase, numbers, and a total of 3-24 characters
$storageAccountName = "st$($prefix)<Storage-Account-name>"

az storage account create `
  --name $storageAccountName `
  --resource-group $apiResourceGroup `
  --location $location `
  --sku Standard_RAGRS `
  --kind StorageV2 `
  --min-tls-version TLS1_2 `
  --allow-blob-public-access true

# 1.2 Update the Container App environment to send logs to Azure Monitor

az containerapp env update --name $managedEnvironment --resource-group $apiResourceGroup --logs-destination azure-monitor
