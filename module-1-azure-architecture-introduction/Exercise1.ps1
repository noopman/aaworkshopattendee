# Module 1: Azure Architecture Introduction
#----------------------------------------------------------------------------------------------------------------------
# Exercise 1

$prefix = "<your-initials>"

# Note: Replacing placeholders in this workshop is such that the whole "<to be replaced>" is replaced with your value.
#       For example: The name you think of is 'foo' and the string with placeholder is "<to be replaced>". Then the outcome is "name".

#----------------------------------------------------------------------------------------------------------------------
# Step 1: Create the resource group and deploy the ARM

az account list-locations -o table
# Choose a location from the list and set it as the location variable.
$location = "<resource-group-location>"

# 1.1 Create your resource-group for APIs.

$apiResourceGroup = "rg-$($prefix)-<resource-group-name>"
az group create --name $apiResourceGroup --location $location

# 1.2 Create a resource-group for the database.

$dbResourceGroup = "rg-$($prefix)-<resource-group-name>"
az group create --name $dbResourceGroup --location $location

# 1.3 Set the variables used on deployment.

# Your github owner name (lowercase).
$gitRepositoryOwner = "<owner-repository-github>"

# Your Github token (PAT) value. Created in module 0.
$gitPAT = "<github-PAT>"

# Cosmos Database Account name.
$cosmosDbAccount = "cosmos-$($prefix)-<db-account-name>"

# Bot container name.
$botApi = "$($prefix)<botapi-container-name>"

# Game container name.
$gameApi = "$($prefix)<gameapi-container-name>"

# Managed Environment resource name.
$managedEnvironment = "$($prefix)<managed-environment-name>"

# Vnet name for managed environment.
$vnetName = "$($prefix)<vnet-name>"

# Subnet name for managed environment.
$environmentSubnet = "$($prefix)<environment-subnet-name>"

# Set the local path to the API ARM deployment file from the \infra\arm folder in this project.
cd "<path-to-project-folder>\infra\arm"

# 1.4 Deploy the API using an ARM template and your variables.

az deployment group create `
  --resource-group $apiResourceGroup `
  --template-file azuredeployAPI.json `
  --parameters containerapps_bot_api_name=$botApi containerapps_game_api_name=$gameApi managedEnvironments_env_name=$managedEnvironment location=$location virtualNetworks_vnet_name=$vnetName vnet_subnet_name="default" environment-subnet-name=$environmentSubnet

# 1.5 Deploy the database using an ARM template and your variables.

az deployment group create `
  --resource-group $dbResourceGroup `
  --template-file azuredeployDB.json `
  --parameters databaseAccounts_db_name=$cosmosDbAccount location=$location

#----------------------------------------------------------------------------------------------------------------------






















#----------------------------------------------------------------------------------------------------------------------
# Step 2: Create an Azure Static Web App

# 2.0 Create your resource-group for static web app for the UI app.

$appResourceGroup = "rg-$($prefix)-<resource-group-name>"
az group create --name $appResourceGroup --location $location

# 2.1 Deploy your static web app in the same Resource Group with the APIs.

$staticWebName = "swa-$($prefix)-<Static-Web-App-Name>"

$githubrepositoryurl = "<Your Github Repository url>"
$branch = "<The branch you want to use for deployment>"

az staticwebapp create `
  --name $staticWebName `
  --resource-group $appResourceGroup `
  --source $githubrepositoryurl `
  --branch $branch `
  --app-location "/module-1-azure-architecture-introduction/src/Exercise_1/RockPaperScissors" `
  --api-location "/module-1-azure-architecture-introduction/src/Exercise_1/RockPaperScissorsAPI" `
  --output-location "wwwroot" `
  --login-with-github

# 2.2 Configure an environment variable to connect your Static Web App with your game Container Api.

# Hostname of bot container url.
function Get-ContainerAppFqdn {
  param (
    [string]$resourceGroup,
    [string]$containerAppName
  )
  return az containerapp show --resource-group $resourceGroup --name $containerAppName |
    ConvertFrom-Json |
    Select-Object -ExpandProperty properties |
    Select-Object -ExpandProperty configuration |
    Select-Object -ExpandProperty ingress |
    Select-Object -ExpandProperty fqdn
}

# Hostname of game container url.
$gameContainerHN = Get-ContainerAppFqdn -resourceGroup $apiResourceGroup -containerAppName $gameApi

# Url created on game api container. (You can get this from the Azure Portal.)
$gameContainerUrl = "https://$gameContainerHN"

$botContainerHN = Get-ContainerAppFqdn -resourceGroup $apiResourceGroup -containerAppName $botApi

# Your Bot container api url. (You can get this from the Azure Portal.)
$botContainerUrl = "https://$botContainerHN"

# Set the environment variables for the Static Web App to connect with the game and bot container APIs.
az staticwebapp appsettings set `
  --name $staticWebName `
  --setting-names `
  "GAMEAPI_URL=$gameContainerUrl" "BOTAPI_URL=$botContainerUrl"

# 2.3 At the end of this step you will be able to see your Static Web app deployed in Azure Portal.

#----------------------------------------------------------------------------------------------------------------------





















#----------------------------------------------------------------------------------------------------------------------
# Step 3: Configure dapr statestore using Cosmos DB

# 3.1 Install az containerapp extension.

#az extension list

az extension add --name containerapp --upgrade

# 3.2 Configuring statestore using statestore.yaml file from the local *infra* folder.

# The path to the statestore.yaml file from the /infra folder in this project.
cd "<your-folder-for-the-file-statestore.yaml>"

$cosmosUrl = az cosmosdb show --name $cosmosDbAccount --resource-group $dbResourceGroup --query documentEndpoint --output tsv
$cosmosPrimaryKey = az cosmosdb keys list --name $cosmosDbAccount --resource-group $dbResourceGroup --query primaryMasterKey --output tsv

# 3.3 Open the file and edit the following variables:

$cosmosUrl | clip # => <cosmos-url>
$cosmosPrimaryKey | clip # => <cosmos-primary-key>

# 3.4 Update the Managed Environment.

az containerapp env dapr-component set `
  --name $managedEnvironment `
  --resource-group $apiResourceGroup `
  --dapr-component-name statestore `
  --yaml statestore.yaml

#----------------------------------------------------------------------------------------------------------------------





















#----------------------------------------------------------------------------------------------------------------------
# Step 4: Configure environment variables for Azure Container Apps

# 4.1 Configure environment variable for Game Container Api.

az containerapp up `
  --name $gameApi `
  --resource-group $apiResourceGroup `
  --image ghcr.io/$gitRepositoryOwner/gameapi-rockpaperscissors:latest `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner `
  --registry-password $gitPAT `
  --env-vars GAME_API_BOTAPI="$botContainerUrl" # This is the url of the bot container api.

# 4.2 Configure environment variable for Bot Container Api.

az containerapp up `
  --name $botApi `
  --resource-group $apiResourceGroup `
  --image ghcr.io/$gitRepositoryOwner/botapi-rockpaperscissors:latest `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner `
  --registry-password $gitPAT `
  --env-vars BOT_API_SESSION_URL=$gameContainerUrl # This is the url of the game container api.

#----------------------------------------------------------------------------------------------------------------------





















#----------------------------------------------------------------------------------------------------------------------
# Step 5: Deploy the second Container App on another region

# Choose a secondary location from the list and set it as the location variable.
az account list-locations -o table
$location2 = "<location-name>"

# 5.1 Create the resource group.

# Second API resource group name.
$apiResourceGroup2 = "rg-$($prefix)-<resource-group-name>"
az group create --name $apiResourceGroup2 --location $location2

# 5.2 Create the environment.

# Second managed environment name.
$managedEnvironment2 = "$($prefix)<second-managed-environment-name>"

# Deploy a second managed environment on the second region, but not with ARM template, instead use the az containerapp command.
az containerapp env create `
  --name $managedEnvironment2 `
  --resource-group $apiResourceGroup2 `
  --logs-destination none `
  --location $location2

# 5.3 Update the Managed Environment.

# Update environment with the statestore.yaml file.
az containerapp env dapr-component set `
  --name $managedEnvironment2 `
  --resource-group $apiResourceGroup2 `
  --dapr-component-name statestore `
  --yaml statestore.yaml

# 5.4 Create your second Container App and save its host name in a variable for later.

# Your second bot container name.
$botApi2 = "$($prefix)<second-botapi-container-name>"

# Deploy the second bot container on the second region (in managed environment 2).
az containerapp create `
  --name $botApi2 `
  --resource-group $apiResourceGroup2 `
  --environment $managedEnvironment2 `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner `
  --registry-password $gitPAT `
  --image ghcr.io/$gitRepositoryOwner/botapi-rockpaperscissors:latest `
  --target-port 8080 `
  --ingress external `
  --query properties.configuration.ingress.fqdn `
  --env-vars BOT_API_SESSION_URL=$gameContainerUrl `
  --enable-dapr --dapr-app-id botapi `
  --dapr-app-port 8080

# Second bot container hostname.
$botContainerHN2 = Get-ContainerAppFqdn -resourceGroup $apiResourceGroup2 -containerAppName $botApi2

#----------------------------------------------------------------------------------------------------------------------





















#----------------------------------------------------------------------------------------------------------------------
# Step 6: Configure Front Door to connect both regions from bot Container Api

# 6.1. Create a new resource-group for Front Door.

# Network resource group name.
$networkRGName = "rg-$($prefix)-<resource-group-name>"
az group create --name $networkRGName --location $location

# 6.2 Create Azure Front Door profile.

# Azure Front Door profile.
$frontDoorProfileName = "$($prefix)<profile-name>"

# Create Azure Front Door profile.
az afd profile create `
  --profile-name $frontDoorProfileName `
  --resource-group $networkRGName `
  --sku Standard_AzureFrontDoor

# 6.3 Create Azure Front Door endpoint.

# Azure Front Door endpoint.
$frontDoorEndpointName = "$($prefix)<endpoint-name>"

az afd endpoint create `
  --resource-group $networkRGName `
  --endpoint-name $frontDoorEndpointName `
  --profile-name $frontDoorProfileName `
  --enabled-state Enabled

# 6.4 Create an origin group.

# Origin group name.
$fdOriginGroupName = "$($prefix)<origin-group-name>"

az afd origin-group create `
  --resource-group $networkRGName `
  --origin-group-name $fdOriginGroupName `
  --profile-name $frontDoorProfileName `
  --probe-request-type GET `
  --probe-protocol HTTPS `
  --probe-interval-in-seconds 10 `
  --probe-path "/" `
  --sample-size 4 `
  --successful-samples-required 3 `
  --additional-latency-in-milliseconds 50 `
  --enable-health-probe true

# 6.5 Create origins.

# Create first origin

# First origin name
$firstOriginName = "$($prefix)<first-origin-name>"

az afd origin create `
  --resource-group $networkRGName `
  --host-name $botContainerHN `
  --profile-name $frontDoorProfileName `
  --origin-group-name $fdOriginGroupName `
  --origin-name $firstOriginName `
  --origin-host-header $botContainerHN `
  --priority 1 `
  --weight 1000 `
  --enabled-state Enabled `
  --http-port 8080 `
  --https-port 443 `
  --enable-private-link false

# Create second origin

# Second origin name
$secondOriginName = "$($prefix)<second-origin-name>"

az afd origin create `
  --resource-group $networkRGName `
  --host-name $botContainerHN2 `
  --profile-name $frontDoorProfileName `
  --origin-group-name $fdOriginGroupName `
  --origin-name $secondOriginName `
  --origin-host-header $botContainerHN2 `
  --priority 2 `
  --weight 1000 `
  --enabled-state Enabled `
  --http-port 8080 `
  --https-port 443 `
  --enable-private-link false

# 6.6 Create Front Door route.

az afd route create `
  --resource-group $networkRGName `
  --profile-name $frontDoorProfileName `
  --endpoint-name $frontDoorEndpointName `
  --forwarding-protocol MatchRequest `
  --route-name route `
  --https-redirect Enabled `
  --origin-group $fdOriginGroupName `
  --supported-protocols Http Https `
  --link-to-default-domain Enabled

# 6.7 List endpoint to get the Front Door link and save it on a variable.

$fdEndpoint = az afd endpoint show `
  --resource-group $networkRGName `
  --profile-name $frontDoorProfileName `
  --endpoint-name $frontDoorEndpointName

$fdEndpoint = $fdEndpoint | ConvertFrom-Json

# Front Door endpoint url for game.
$frontDoorBotEndpoint = "https://$($fdEndpoint.hostName)"

#----------------------------------------------------------------------------------------------------------------------





























#----------------------------------------------------------------------------------------------------------------------
# Step 7: Configure Front Door to connect both regions from game Container Api

# 7.1 Create gameapi container on second region.

# Second game container name.
$gameApi2 = "$($prefix)<second-gameapi-container-name>"

# Deploy the second game container on the second region (in managed environment 2).
az containerapp create `
  --name $gameApi2 `
  --resource-group $apiResourceGroup2 `
  --environment $managedEnvironment2 `
  --registry-server ghcr.io --registry-username $gitRepositoryOwner --registry-password $gitPAT `
  --image ghcr.io/$gitRepositoryOwner/gameapi-rockpaperscissors:latest `
  --target-port 8080 `
  --ingress external `
  --query properties.configuration.ingress.fqdn `
  --env-vars GAME_API_BOTAPI="$botContainerUrl" `
  --enable-dapr `
  --dapr-app-id gameapi `
  --dapr-app-port 8080

# Second game container hostname.
$gameContainerHN2 = "<second-bot-container-host-name>"

# 7.2 Create another endpoint.

# Second endpoint name.
$frontDoorGameEndpointName = "$($prefix)<second-endpoint-name>"

az afd endpoint create `
  --resource-group $networkRGName `
  --endpoint-name $frontDoorGameEndpointName `
  --profile-name $frontDoorProfileName `
  --enabled-state Enabled

# 7.3 Create a second origin group.

# Second origin group name.
$fdGameOriginGroupName = "$($prefix)<origin-group-name>"

az afd origin-group create `
  --resource-group $networkRGName `
  --origin-group-name $fdGameOriginGroupName `
  --profile-name $frontDoorProfileName `
  --probe-request-type GET `
  --probe-protocol HTTPS `
  --probe-interval-in-seconds 10 `
  --probe-path "/" `
  --sample-size 4 `
  --successful-samples-required 3 `
  --additional-latency-in-milliseconds 50 `
  --enable-health-probe true

# 7.4 Create origins.

# Create first game origin
az afd origin create `
  --resource-group $networkRGName `
  --host-name $gameContainerHN `
  --profile-name $frontDoorProfileName `
  --origin-group-name $fdGameOriginGroupName `
  --origin-name $firstOriginName `
  --origin-host-header $gameContainerHN `
  --priority 1 `
  --weight 1000 `
  --enabled-state Enabled `
  --http-port 8080 `
  --https-port 443 `
  --enable-private-link false

# Create second game origin
az afd origin create `
  --resource-group $networkRGName `
  --host-name $gameContainerHN2 `
  --profile-name $frontDoorProfileName `
  --origin-group-name $fdGameOriginGroupName `
  --origin-name $secondOriginName `
  --origin-host-header $gameContainerHN2 `
  --priority 2 `
  --weight 1000 `
  --enabled-state Enabled `
  --http-port 8080 `
  --https-port 443 `
  --enable-private-link false

# 7.5 Create Front Door route for game.

az afd route create `
  --resource-group $networkRGName `
  --profile-name $frontDoorProfileName `
  --endpoint-name $frontDoorGameEndpointName `
  --forwarding-protocol MatchRequest `
  --route-name route `
  --https-redirect Enabled `
  --origin-group $fdGameOriginGroupName `
  --supported-protocols Http Https `
  --link-to-default-domain Enabled

# 7.6 List second endpoint to get the Front Door link and save it on a variable.

# Front Door endpoint for game.
$frontDoorGameEndpoint = az afd endpoint show `
  --resource-group $networkRGName `
  --profile-name $frontDoorProfileName `
  --endpoint-name $frontDoorGameEndpointName
$frontDoorGameEndpoint = $frontDoorGameEndpoint | ConvertFrom-Json
$frontDoorGameEndpoint = "https://$($frontDoorGameEndpoint.hostName)"

#----------------------------------------------------------------------------------------------------------------------






















#----------------------------------------------------------------------------------------------------------------------
# Step 8: Use the endpoints to configure Azure Container Apps and Static Web

# 8.1 Modify environment variables for Azure Container Apps.

az containerapp up `
  --name $gameApi `
  --resource-group $apiResourceGroup `
  --image ghcr.io/$gitRepositoryOwner/gameapi-rockpaperscissors:latest `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner `
  --registry-password $gitPAT `
  --env-vars GAME_API_BOTAPI=$frontDoorBotEndpoint # This is the url of the front door bot endpoint.

az containerapp up `
  --name $botApi `
  --resource-group $apiResourceGroup `
  --image ghcr.io/$gitRepositoryOwner/botapi-rockpaperscissors:latest `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner `
  --registry-password $gitPAT `
  --env-vars BOT_API_SESSION_URL=$frontDoorGameEndpoint # This is the url of the front door game endpoint.

az containerapp up `
  --name $gameApi2 `
  --resource-group $apiResourceGroup2 `
  --image ghcr.io/$gitRepositoryOwner/gameapi-rockpaperscissors:latest `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner `
  --registry-password $gitPAT `
  --env-vars GAME_API_BOTAPI=$frontDoorBotEndpoint

az containerapp up `
  --name $botApi2 `
  --resource-group $apiResourceGroup2 `
  --image ghcr.io/$gitRepositoryOwner/botapi-rockpaperscissors:latest `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner `
  --registry-password $gitPAT `
  --env-vars BOT_API_SESSION_URL=$frontDoorGameEndpoint

# 8.2 Modify environment variables for Static Web App.

az staticwebapp appsettings set `
  --name $staticWebName `
  --setting-names "GAMEAPI_URL=$frontDoorGameEndpoint" "BOTAPI_URL=$frontDoorBotEndpoint"

# 8.3 Add `*` to CORS Settings Azure Container Apps properties -> configuration -> ingress -> corsPolicy on the container apps in the second region.

# Configure CORS for the bot api container in the second region.
az containerapp ingress cors update `
  --resource-group $apiResourceGroup2 `
  --name $botApi2 `
  --allowed-headers * --allowed-origins *

# Configure CORS for the game api container in the second region.
az containerapp ingress cors update `
  --resource-group $apiResourceGroup2 `
  --name $gameApi2 `
  --allowed-headers * --allowed-origins *
