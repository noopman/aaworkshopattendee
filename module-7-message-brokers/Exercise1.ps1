# Module 7: Message Brokers
#----------------------------------------------------------------------------------------------------------------------
# Exercise 1

# ---------------------------------------------------------------------------------------------------------------------
# Step 1: Deploy an Azure Event Grid Topic

# 1.1 Enable Event Grid resource provider for your subscription if it was not enabled before

az provider register --namespace Microsoft.EventGrid
az provider show --namespace Microsoft.EventGrid --query "registrationState"

# 1.2 Create a new Resource Group for your Event Grid

$gridResourceGroup = "rg-$($prefix)-<event-grid-resource-group-name>"
az group create --name $gridResourceGroup --location $location

# 1.0 Install the Event Grid az cli extension

az extension list --output table
az extension add --name eventgrid

# 1.3 Create your Event Grid Topic

$topicName = "$($prefix)-<topic-name>"
az eventgrid topic create `
  --name $topicName `
  --resource-group $gridResourceGroup `
  --location $location

# ---------------------------------------------------------------------------------------------------------------------
# Step 2: Deploy the new versions of your containers

# 2.1 Redeploy the StatsAPI

# You can set the TTL to a higher value as now it will also update on game finish.

$ttl = 86400 # one day

az containerapp up `
  --name $statsApi `
  --resource-group $apiResourceGroup `
  --image ghcr.io/$gitRepositoryOwner/statsapi-rockpaperscissors:module7-ex1 `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner `
  --registry-password $gitPAT `
  --env-vars STATS_API_DB_CONNECTION_STRING=$dConnection STATS_API_TTL=$ttl

# 2.2 Fetch the Event Grid Credentials

$eventGridEndpoint = "<topic-endpoint>"
$eventGridKey = "<topic-key>"

# 2.3 Redeploy the GameAPI

az containerapp up `
  --name $gameApi `
  --resource-group $apiResourceGroup `
  --image ghcr.io/$gitRepositoryOwner/gameapi-rockpaperscissors:module7-ex1 `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner `
  --registry-password $gitPAT `
  --env-vars GAME_API_SIGNALR=$signalrEndpoint GAME_API_BOTAPI=$botContainerUrl GAME_API_HOST=$gameContainerUrl GAME_API_SMTPSERVER=$smtp GAME_API_SMTP_SENDER=$senderDnR GAME_API_STATSAPI=$statsContainerUrl GAME_API_EVENT_GRID_ENDPOINT=$eventGridEndpoint GAME_API_EVENT_GRID_KEY=$eventGridKey

# ---------------------------------------------------------------------------------------------------------------------
# Step 3: Create a subscription for your StatsAPI

# 3.1 Define your subscription endpoint and the Resource ID of your Topic
$subscriptionEndpoint = "<stats-api-container-url>/api/eventhandler"

$topicResourceId = az eventgrid topic show `
  --name $topicName `
  --resource-group $gridResourceGroup `
  --query "id" --output tsv

# 3.2 Create a Subscription for the Topic

$subscriptionName = "$($prefix)-<event-subscription-name>"

az eventgrid event-subscription create `
  --name $subscriptionName `
  --source-resource-id $topicResourceId `
  --endpoint $subscriptionEndpoint
