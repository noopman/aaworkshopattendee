# Module 1: Azure Architecture Introduction
#----------------------------------------------------------------------------------------------------------------------
# Exercise 1

#----------------------------------------------------------------------------------------------------------------------
# Step 1: Create the resource group and deploy the ARM

az account list-locations -o table
$location = '<resource-group-location>'

# 1.1 Create your resource-group for APIs.

$apiResourceGroup = '<resource-group-name>'
az group create --name $apiResourceGroup --location $location

# 1.2 Create a resource-group for the database.

$dbResourceGroup = '<resource-group-name>'
az group create --name $dbResourceGroup --location $location

# 1.3 Set the variables used on deployment.

# Your github owner name (lowercase).
$gitRepositoryOwner = '<owner-repository-github>'

# Your Github token (PAT) value. Created in module 0.
$gitPAT = '<github-PAT>'

# Cosmos Database Account name.
$cosmosDbAccount = '<db-account-name>'

# Bot container name.
$botApi = '<botapi-container-name>'

# Game container name.
$gameApi = '<gameapi-container-name>'

# Managed Environment resource name.
$managedEnvironment = '<managed-environment-name>'

# Vnet name for managed environment.
$vnetName = '<vnet-name>'

# Subnet name for managed environment.
$environmentSubnet = '<environment-subnet-name>'

# 1.4 Deploy the ARM using configured variables.

# Set the path to your ARM deploy

# Local path to the API ARM deployment file from the /infra folder in this project.
cd '<path-to-project-folder>\infra\arm'

# Verify that all these have a value before running the deployment.
$apiResourceGroup
$botApi
$gameApi
$managedEnvironment
$location
$vnetName
$environmentSubnet

# Deploy the API.
az deployment group create `
  --resource-group $apiResourceGroup `
  --template-file azuredeployAPI.json `
  --parameters containerapps_bot_api_name=$botApi containerapps_game_api_name=$gameApi managedEnvironments_env_name=$managedEnvironment location=$location virtualNetworks_vnet_name=$vnetName vnet_subnet_name="default" environment-subnet-name=$environmentSubnet

# Deploy the database.
az deployment group create `
  --resource-group $dbResourceGroup `
  --template-file azuredeployDB.json `
  --parameters databaseAccounts_db_name=$cosmosDbAccount location=$location

#----------------------------------------------------------------------------------------------------------------------






















#----------------------------------------------------------------------------------------------------------------------
# Step 2: Create an Azure Static Web App

# 2.1 Deploy your static web app in the same Resource Group with the APIs.

$staticWeb = '<Static-Web-App-Name>'

$githubrepositoryurl = '{Your Github Repository url}'
$branch = '{The branch you want to use for deployment}'

# Verify that all these have a value before running the deployment.
$staticWeb
$apiResourceGroup
$githubrepositoryurl
$branch

az staticwebapp create `
  --name $staticWeb `
  --resource-group $apiResourceGroup `
  --source $githubrepositoryurl `
  --branch $branch `
  --app-location '/module-1-azure-architecture-introduction/src/Exercise_1/RockPaperScissors' `
  --api-location '/module-1-azure-architecture-introduction/src/Exercise_1/RockPaperScissorsAPI' `
  --output-location 'wwwroot' `
  --login-with-github

# 2.2 Configure an environment variable to connect your Static Web App with your game Container Api.

# Url created on game api container. (You can get this from the Azure Portal.)
$gameContainerUrl = '<game-api-container-url>'

# Hostname of game container url.
$gameContainerHN = '<game-container-host-name>'

# Your Bot container api url. (You can get this from the Azure Portal.)
$botContainerUrl = '<bot-container-url>'

# Hostname of bot container url.
$botContainerHN = '<bot-container-host-name>'

# Verify that all these have a value before running the deployment.
$gameContainerUrl
$gameContainerHN
$botContainerUrl
$botContainerHN

az staticwebapp appsettings set `
  --name $staticWeb `
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
cd '<your-folder-for-the-file-statestore.yaml>'

# 3.3 Open the file and edit the following variables: `<cosmos-url>` and `<cosmos-primary-key>`.

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

$gameApi
$apiResourceGroup
$gitRepositoryOwner
#$gitPAT
$botContainerUrl

az containerapp up `
  --name $gameApi `
  --resource-group $apiResourceGroup `
  --image ghcr.io/$gitRepositoryOwner/gameapi-rockpaperscissors:latest `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner `
  --registry-password $gitPAT `
  --env-vars GAME_API_BOTAPI="$botContainerUrl"

# 4.2 Configure environment variable for Bot Container Api.

$botApi
$apiResourceGroup
$gitRepositoryOwner
# $gitPAT
$gameContainerUrl

az containerapp up `
  --name $botApi `
  --resource-group $apiResourceGroup `
  --image ghcr.io/$gitRepositoryOwner/botapi-rockpaperscissors:latest `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner `
  --registry-password $gitPAT `
  --env-vars BOT_API_SESSION_URL=$gameContainerUrl

#----------------------------------------------------------------------------------------------------------------------





















#----------------------------------------------------------------------------------------------------------------------
# Step 5: Deploy the second Container App on another region

# 5.1 Create the resource group.

# Second resource group name.
$resourceGroup2 = '<resource-group-name>'

# Second location for resource group.
$location2 = '<location-name>'

# 5.2 Run the create command.

az group create `
  --name $resourceGroup2 `
  --location $location2

# 5.3 Create the environment.

# Second managed environment name.
$managedEnvironment2 = '<second-managed-environment-name>'

az containerapp env create `
  --name $managedEnvironment2 `
  --resource-group $resourceGroup2 `
  --location $location2

# 5.4 Update the Managed Environment.

az containerapp env dapr-component set `
  --name $managedEnvironment2 `
  --resource-group $resourceGroup2 `
  --dapr-component-name statestore `
  --yaml statestore.yaml

# 5.5 Create your second Container App and save its host name in a variable for later.

# Your second bot container name.
$botApi2 = '<second-botapi-container-name>'

$botApi2
$resourceGroup2
$managedEnvironment2
$gitRepositoryOwner
#$gitPAT
$gameContainerUrl

az containerapp create `
  --name $botApi2 `
  --resource-group $resourceGroup2 `
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
$botContainerHN2 = '<second-bot-container-host-name>'

#----------------------------------------------------------------------------------------------------------------------





















#----------------------------------------------------------------------------------------------------------------------
# Step 6: Configure Front Door to connect both regions from bot Container Api

# 6.1. Create a new resource-group for Front Door.

$NetworkResourceGroup="<resource-group-name>" # resource-group-name> = Your network resource group name

az group create `
  --name $NetworkResourceGroup `
  --location $location

# 6.2 Create Azure Front Door profile.

$ProfileName="<profile-name>" # <profile-name> = Name your azure front door

az afd profile create `
  --profile-name $ProfileName `
  --resource-group $NetworkResourceGroup `
  --sku Standard_AzureFrontDoor

# 6.3 Create Azure Front Door endpoint.

$EndpointName="<endpoint-name>" # <endpoint-name> = Name your endpoint

az afd endpoint create `
  --resource-group $NetworkResourceGroup `
  --endpoint-name $EndpointName `
  --profile-name $ProfileName `
  --enabled-state Enabled

# 6.4 Create an origin group.

$OriginGroupName="<origin-group-name>" # <origin-group-name> = Name your origin group

az afd origin-group create `
  --resource-group $NetworkResourceGroup `
  --origin-group-name $OriginGroupName `
  --profile-name $ProfileName `
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

# <first-origin-name> = First origin name
az afd origin create --resource-group $NetworkResourceGroup --host-name $botContainerHN --profile-name $ProfileName --origin-group-name $OriginGroupName --origin-name <first-origin-name> --origin-host-header $botContainerHN --priority 1 --weight 1000 --enabled-state Enabled --http-port 8080 --https-port 443 --enable-private-link false

# Create second origin

# <second-origin-name> = Second origin name
az afd origin create --resource-group $NetworkResourceGroup --host-name $botContainerHN2 --profile-name $ProfileName --origin-group-name $OriginGroupName --origin-name <second-origin-name> --origin-host-header $botContainerHN2 --priority 2 --weight 1000 --enabled-state Enabled --http-port 8080 --https-port 443 --enable-private-link false

# 6.6 Create Front Door route.

az afd route create --resource-group $NetworkResourceGroup --profile-name $ProfileName --endpoint-name $EndpointName  --forwarding-protocol MatchRequest --route-name route --https-redirect Enabled --origin-group $OriginGroupName --supported-protocols Http Https --link-to-default-domain Enabled

# 6.7 List endpoint to get the Front Door link and save it on a variable.

az afd endpoint show --resource-group $NetworkResourceGroup --profile-name $ProfileName --endpoint-name $EndpointName

$Endpoint="https://<endpoint-url>" # <endpoint-url> = Front Door endpoint url for game

#----------------------------------------------------------------------------------------------------------------------





























#----------------------------------------------------------------------------------------------------------------------
# Step 7: Configure Front Door to connect both regions from game Container Api

# 7.1 Create gameapi container on second region.

$gameApi2="<second-gameapi-container-name>" # <second-gameapi-container-name> = Your second container name

az containerapp create --name $gameApi2 --resource-group $resourceGroup2 --environment $managedEnvironment2 --registry-server ghcr.io --registry-username $gitRepositoryOwner --registry-password $gitPAT --image  ghcr.io/$gitRepositoryOwner/gameapi-rockpaperscissors:latest --target-port 8080 --ingress external --query properties.configuration.ingress.fqdn --env-vars GAME_API_BOTAPI="$botContainerUrl" --enable-dapr --dapr-app-id gameapi --dapr-app-port 8080

$gameContainerHN2="<second-bot-container-host-name>" # <second-bot-container-host-name> = Second game container hostname

# 7.2 Create another endpoint.

$EndpointName2="<second-endpoint-name>" # <second-endpoint-name> = Name your endpoint

az afd endpoint create --resource-group $NetworkResourceGroup  --endpoint-name $EndpointName2 --profile-name $ProfileName --enabled-state Enabled

# 7.3 Create a second origin group.

$OriginGroupName2="<origin-group-name>" # <origin-group-name> = Name your second origin group for game

az afd origin-group create --resource-group $NetworkResourceGroup --origin-group-name $OriginGroupName2 --profile-name $ProfileName --probe-request-type GET --probe-protocol HTTPS --probe-interval-in-seconds 10 --probe-path "/" --sample-size 4 --successful-samples-required 3 --additional-latency-in-milliseconds 50 --enable-health-probe true

# 7.4 Create origins.

# Create first game origin

# <first-origin-name> = First origin name for game
az afd origin create --resource-group $NetworkResourceGroup --host-name $gameContainerHN --profile-name $ProfileName --origin-group-name $OriginGroupName2 --origin-name <first-origin-name> --origin-host-header $gameContainerHN --priority 1 --weight 1000 --enabled-state Enabled --http-port 8080 --https-port 443 --enable-private-link false

# Create second game origin

# <second-origin-name> = Second origin name for game
az afd origin create --resource-group $NetworkResourceGroup --host-name $gameContainerHN2 --profile-name $ProfileName --origin-group-name $OriginGroupName2 --origin-name <second-origin-name> --origin-host-header $gameContainerHN2 --priority 2 --weight 1000 --enabled-state Enabled --http-port 8080 --https-port 443 --enable-private-link false

# 7.5 Create Front Door route for game.

az afd route create --resource-group $NetworkResourceGroup --profile-name $ProfileName --endpoint-name $EndpointName2  --forwarding-protocol MatchRequest --route-name route --https-redirect Enabled --origin-group $OriginGroupName2 --supported-protocols Http Https --link-to-default-domain Enabled

# 7.6 List second endpoint to get the Front Door link and save it on a variable.

az afd endpoint show --resource-group $NetworkResourceGroup --profile-name $ProfileName --endpoint-name $EndpointName2

$Endpoint2="https://<endpoint-url>" # <endpoint-url> = Front Door endpoint url for game

#----------------------------------------------------------------------------------------------------------------------






















#----------------------------------------------------------------------------------------------------------------------
# Step 8: Use the endpoints to configure Azure Container Apps and Static Web

# 8.1 Modify environment variables for Azure Container Apps.

az containerapp up --name $gameApi --resource-group $apiResourceGroup --image ghcr.io/$gitRepositoryOwner/gameapi-rockpaperscissors:latest --registry-server ghcr.io --registry-username $gitRepositoryOwner --registry-password $gitPAT --env-vars GAME_API_BOTAPI=$Endpoint

az containerapp up --name $botApi --resource-group $apiResourceGroup --image ghcr.io/$gitRepositoryOwner/botapi-rockpaperscissors:latest --registry-server ghcr.io --registry-username $gitRepositoryOwner --registry-password $gitPAT --env-vars BOT_API_SESSION_URL=$Endpoint2

az containerapp up --name $gameApi2 --resource-group $resourceGroup2 --image ghcr.io/$gitRepositoryOwner/gameapi-rockpaperscissors:latest --registry-server ghcr.io --registry-username $gitRepositoryOwner --registry-password $gitPAT --env-vars GAME_API_BOTAPI=$Endpoint

az containerapp up --name $botApi2 --resource-group $resourceGroup2 --image ghcr.io/$gitRepositoryOwner/botapi-rockpaperscissors:latest --registry-server ghcr.io --registry-username $gitRepositoryOwner --registry-password $gitPAT --env-vars BOT_API_SESSION_URL="$Endpoint2"

# 8.2 Modify environment variables for Static Web App.

az staticwebapp appsettings set --name $staticWeb --setting-names "GAMEAPI_URL=$Endpoint2" "BOTAPI_URL=$Endpoint"

# 8.3 Add `*` to CORS manually under Settings tab for Azure Container Apps created on second region from Azure Portal.
