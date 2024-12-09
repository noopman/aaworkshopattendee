# Module 4: Caching Strategies
#----------------------------------------------------------------------------------------------------------------------
# Exercise 1

# ----------------------------------------------------------------------------------------------------------------------
# Step 1: Deploy StatsAPI

$statsApi = "<stats-container-name>"

$dConnection = "<DB-connection-string>"

$ttl = "<data-time-to-live-seconds>"

az containerapp create `
  --name $statsApi `
  --resource-group $apiResourceGroup `
  --registry-server ghcr.io --registry-username $gitRepositoryOwner --registry-password $gitPAT `
  --image ghcr.io/$gitRepositoryOwner/statsapi-rockpaperscissors:module4-ex1 `
  --environment $managedEnvironment `
  --ingress external `
  --target-port 8080 `
  --query properties.configuration.ingress.fqdn `
  --env-vars STATS_API_DB_CONNECTION_STRING=$dConnection STATS_API_TTL=$ttl

# ----------------------------------------------------------------------------------------------------------------------
# Step 3: Redeploy GameAPI and the web app

$statsContainerUrl = "<stats-container-url>"

az containerapp up `
  --name $gameApi `
  --resource-group $apiResourceGroup `
  --image ghcr.io/$gitRepositoryOwner/gameapi-rockpaperscissors:module4-ex1 `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner --registry-password $gitPAT `
  --env-vars GAME_API_SIGNALR=$signalrEndpoint GAME_API_BOTAPI=$botContainerUrl GAME_API_HOST=$gameContainerUrl GAME_API_SMTPSERVER=$smtp GAME_API_SMTP_SENDER=$senderDnR GAME_API_STATSAPI=$statsContainerUrl
