# Module 5: Security Best Practices
#----------------------------------------------------------------------------------------------------------------------
# Exercise 1

# ----------------------------------------------------------------------------------------------------------------------
# Step 1: Create a Private Endpoint for CosmosDB

# 1. Update the subnet to disable private endpoint network policies.
#    You first need to define your Default Subnet name,
#    which will be "default" as defined in the ARM from Module 1, so you shouldn't change it.

$defaultSubnetName = "default"
az network vnet subnet update `
  --name $defaultSubnetName `
  --resource-group $apiResourceGroup `
  --vnet-name $vnetName `
  --disable-private-endpoint-network-policies true

# 2. You need to save the Resource ID for the CosmosDB to create a private endpoint.

$cosmosDbId = az cosmosdb show -n $cosmosDbAccount -g $dbResourceGroup --query id --output tsv

# 3. Create the Private Endpoint for the CosmosDB.

$pepName = "pep-$($prefix)-<private-endpoint-name>"
$conName = "con-$($prefix)-<private-link-service-connection-name>"

az network private-endpoint create `
  --name $pepName `
  --resource-group $apiResourceGroup `
  --vnet-name $vnetName `
  --subnet $defaultSubnetName `
  --private-connection-resource-id $cosmosDbId `
  --group-ids Sql `
  --connection-name $conName

# 4. To use the newly created Private Endpoint, you have to create a Private DNS Zone resource.

$zoneName = "privatelink.documents.azure.com"
az network private-dns zone create --name $zoneName --resource-group $apiResourceGroup

# 5. The DNS Zone needs to be linked the to Virtual Network.

$zoneLinkName = "privatelink-$($prefix)-<zone-link-name>"

az network private-dns link vnet create `
  --name $zoneLinkName `
  --resource-group $apiResourceGroup `
  --zone-name $zoneName `
  --virtual-network $vnetName `
  --registration-enabled false

# 6. Now you can create a DNS Zone Group associated with the Private Endpoint.

$zoneGroupName = "zone-$($prefix)-<zone-group-name>"

az network private-endpoint dns-zone-group create `
  --name $zoneGroupName `
  --resource-group $apiResourceGroup `
  --endpoint-name $pepName `
  --private-dns-zone $zoneName `
  --zone-name "zone"

# ----------------------------------------------------------------------------------------------------------------------
