# Module 2: External Communication
#----------------------------------------------------------------------------------------------------------------------
# Exercise 1

#----------------------------------------------------------------------------------------------------------------------
# Step 1: Create the Azure SignalR Service Resource
# To use SignalR in your applications, you need to first deploy
# an Azure SignalR Service so that the hub will be hosted on the cloud.

# 1.1 Give a name to your SignalR Resource.

$signalr = "<signalr-name>"

# 1.2 Create the SignalR resource.

az signalr create `
  --name $signalr `
  --resource-group $emailResourceGroup `
  --sku "Free_F1" `
  --unit-count "1" `
  --service-mode "Default"

#----------------------------------------------------------------------------------------------------------------------
# Step 2: Copy the Connection string of the SignalR Service
#         To get the Connection string of your SignalR Service,
#         you need to access the newly created resource in the Azure Portal.

# 2.1 Navigate to your SignalR Service Resource. You should find it in the resource group where you created it.

# 2.2 In the side menu, under Settings, you should find the Connection strings tab.

# 2.3 Copy the Primary Connection string from the For access key section.

# 2.4 Set the Connection string inside your console.

$signalrEndpoint = "<singalr-connection-string>"

# Bonus: You can also get the connection string using the Azure CLI command below.
$signalrEndpoint = az signalr key list --name $signalr --resource-group $emailResourceGroup --query primaryConnectionString --output tsv

#----------------------------------------------------------------------------------------------------------------------
# Step 3: Create an Azure Communication Service resource

# 3.0. (Extra step) Before creating the Azure Communication Service, you can install the communication extension for the Azure CLI.

# [NOTE] If you do not explicitly install the communication extension, the az command will prompt you to install it on the first use.

# Check if you have the extension 'communication' installed:
az extension list --output table

# List the versions of the 'communication' extension:
az extension list-versions --name communication --output table

# If you don't have the extension installed, install it:
az extension add --name communication

# If you have the extension installed, update it to the latest version:
az extension update --name communication

# 3.1. To send e-mails to the users of the application, you will need an Azure Communication Service with SMTP capabilities.

# Name your Azure Communication Service.
$acsName = "acs-$prefix-<communication-service-name>"

# If you want to choose a different region for your Azure Communication Service "--data-location", you can review the available regions on https://learn.microsoft.com/en-us/azure/communication-services/concepts/privacy#data-residency

az communication create `
  --name $acsName `
  --location "Global" `
  --data-location "europe" `
  --resource-group $emailResourceGroup

# 3.2 Azure Communication Service has multiple ways of client communication.
# To use the email functionality, you need an Azure Email Communication Service.

# Name your email service
$emailServiceName = "$prefix-emlsrv"

# Create the Email Communication Service
az communication email create `
  --name $emailServiceName `
  --resource-group $emailResourceGroup `
  --location "Global" `
  --data-location "europe"

# 3.3 The Email Communication Service also needs a Email Communication Services Domain for sending emails.

az communication email domain create `
  --resource-group $emailResourceGroup `
  --domain-name AzureManagedDomain `
  --domain-management AzureManaged `
  --email-service-name $emailServiceName `
  --location "Global"

#----------------------------------------------------------------------------------------------------------------------
# Step 4: Set the Connection String and the Sender Address inside your terminal and redeploy the apps
#         To see the changes of the application, you will have to redeploy the API's container and the Web Application.

# 4.1. You can find the Connection String in the Azure Portal.
# Navigate to your Azure Communication Service resource, on the side menu, under Settings you will find the Keys tab.

# Your SMTP Connection String.
$smtp = "<SMTP-connection-string>"

# Alternative:
# $smtp = az communication list-key --name $acsName --resource-group $emailResourceGroup --query primaryConnectionString --output tsv

# 4.2 Save the DoNotReply email address from which the emails will be sent.
# In the Email Communication Services Domain resource, under the MailFrom addresses tab.

# Your no-reply email address.
$senderDnR = "<Sender>"

<# Alternative:
$mailFromSenderDomain = az communication email domain show `
  --resource-group $emailResourceGroup `
  --name AzureManagedDomain `
  --domain-name AzureManagedDomain `
  --email-service-name $emailServiceName `
  --query "mailFromSenderDomain" --output tsv
$senderDnR = "DoNotReply@$mailFromSenderDomain"
#>

# 4.3 To redeploy the API's with the new Environment Variables, run the following commands:

$botApi
$gameApi
$apiResourceGroup
$gitRepositoryOwner
#$gitPAT
$botContainerUrl
$gameContainerUrl
$signalrEndpoint
$smtp
$senderDnR

<# Ensure that all variables are set correctly before running the commands. Here is an example of how to set the variables:
$botContainerUrl = az containerapp show --name $botApi --resource-group $apiResourceGroup |
  ConvertFrom-Json |
  Select-Object -ExpandProperty properties |
  Select-Object -ExpandProperty configuration |
  Select-Object -ExpandProperty ingress |
  Select-Object -ExpandProperty fqdn
$botContainerUrl = "https://$botContainerUrl"

$gameContainerUrl = az containerapp show --name $gameApi --resource-group $apiResourceGroup |
  ConvertFrom-Json |
  Select-Object -ExpandProperty properties |
  Select-Object -ExpandProperty configuration |
  Select-Object -ExpandProperty ingress |
  Select-Object -ExpandProperty fqdn
$gameContainerUrl = "https://$gameContainerUrl"
#>

# Update the game api container with a new image that has the SignalR functionality and the new environment variables.
az containerapp up `
  --name $gameApi --resource-group $apiResourceGroup `
  --registry-server ghcr.io `
  --image ghcr.io/$gitRepositoryOwner/gameapi-rockpaperscissors:module2-ex1 `
  --registry-username $gitRepositoryOwner --registry-password $gitPAT `
  --env-vars GAME_API_BOTAPI=$botContainerUrl GAME_API_SIGNALR=$signalrEndpoint GAME_API_HOST=$gameContainerUrl GAME_API_SMTPSERVER=$smtp GAME_API_SMTP_SENDER=$senderDnR

# Update the bot api container with a new image that has the SignalR functionality and the new environment variables.
az containerapp up `
  --name $botApi --resource-group $apiResourceGroup `
  --registry-server ghcr.io `
  --image ghcr.io/$gitRepositoryOwner/botapi-rockpaperscissors:module2-ex1 `
  --registry-username $gitRepositoryOwner --registry-password $gitPAT `
  --env-vars BOT_API_SESSION_URL=$gameContainerUrl

#! Should not the containers in the other locations be updated as well?

# 4.5. Update the Environment Variables of the Static Web App in order to use SignalR

az staticwebapp appsettings set `
  --name $staticWebName `
  --setting-names "GAMEAPI_URL=$gameContainerUrl" "BOTAPI_URL=$botContainerUrl"
