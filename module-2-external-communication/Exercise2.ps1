# Module 2: External Communication
#----------------------------------------------------------------------------------------------------------------------
# Exercise 2

#----------------------------------------------------------------------------------------------------------------------
# Step 1: Redeploy the apps


$gameApi
$botApi
$apiResourceGroup
$gitRepositoryOwner
#$gitPAT
$signalrEndpoint
$botContainerUrl
$gameContainerUrl
$smtp
$senderDnR

az containerapp up `
  --name $gameApi `
  --resource-group $apiResourceGroup `
  --registry-server ghcr.io --image ghcr.io/$gitRepositoryOwner/gameapi-rockpaperscissors:module2-ex2 `
  --registry-username $gitRepositoryOwner --registry-password $gitPAT `
  --env-vars GAME_API_SIGNALR=$signalrEndpoint GAME_API_BOTAPI=$botContainerUrl GAME_API_HOST=$gameContainerUrl GAME_API_SMTPSERVER=$smtp GAME_API_SMTP_SENDER=$senderDnR

az containerapp up `
  --name $botApi `
  --resource-group $apiResourceGroup `
  --image ghcr.io/$gitRepositoryOwner/botapi-rockpaperscissors:module2-ex2 `
  --registry-server ghcr.io `
  --registry-username $gitRepositoryOwner --registry-password $gitPAT `
  --env-vars BOT_API_SESSION_URL=$gameContainerUrl

#----------------------------------------------------------------------------------------------------------------------
# Step 4: Redeploy static web app with APIM url

# Gateway url from APIM
$apimUrl = "<your-apim-url>"

az staticwebapp appsettings set --name $staticWebName --setting-names "GAMEAPI_URL=$gameContainerUrl" "APIM_URL=$apimUrl"

#----------------------------------------------------------------------------------------------------------------------
# Step 5:

# 2.2 Check the status of the APIM resource

az apim show `
  --name $apimName `
  --resource-group $emailResourceGroup `
  --query 'provisioningState'
