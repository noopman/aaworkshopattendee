# Module 4: Caching Strategies
#----------------------------------------------------------------------------------------------------------------------
# Exercise 1

# ----------------------------------------------------------------------------------------------------------------------
# Step 1: Deploy StatsAPI

$StatsApi="<stats-container-name>"

$DB_Connection="<DB-connection-string>"

$TTL="<data-time-to-live-seconds>"

az containerapp create -n $StatsApi --resource-group $apiResourceGroup --image ghcr.io/$gitRepositoryOwner/statsapi-rockpaperscissors:module4-ex1 --registry-server ghcr.io --registry-username $gitRepositoryOwner --registry-password $gitPAT --environment $ManagedEnvironment --ingress external --target-port 8080 --query properties.configuration.ingress.fqdn --env-vars STATS_API_DB_CONNECTION_STRING=$DB_Connection STATS_API_TTL=$TTL

# ----------------------------------------------------------------------------------------------------------------------
# Step 3: Redeploy GameAPI and the web app

$StatsContainerUrl="<stats-container-url>"

az containerapp up `
  --name $gameApi `
  --resource-group $apiResourceGroup `
  --image ghcr.io/$gitRepositoryOwner/gameapi-rockpaperscissors:module4-ex1 `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner --registry-password $gitPAT `
  --env-vars GAME_API_SIGNALR=$signalrEndpoint GAME_API_BOTAPI=$botContainerUrl GAME_API_HOST=$gameContainerUrl GAME_API_SMTPSERVER=$smtp GAME_API_SMTP_SENDER=$senderDnR GAME_API_STATSAPI=$StatsContainerUrl
