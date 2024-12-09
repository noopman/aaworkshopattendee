# Module 8: Observability and Monitoring
#----------------------------------------------------------------------------------------------------------------------
# Exercise 1

# ---------------------------------------------------------------------------------------------------------------------
# Step 1: Deploy an Azure Application Insights resource

# 1.1 Deploy a Log Analytics Workspace Resource and save its ID.

$workspaceName = "law-$($prefix)-<analytics-workspace-name>"

$workspaceId = az monitor log-analytics workspace create `
  --resource-group $apiResourceGroup `
  --workspace-name $workspaceName `
  --location $location | ConvertFrom-Json | Select-Object -ExpandProperty id

# Alternatively, you can also read the workspace ID from the created resource.:
# $workspaceId = az monitor log-analytics workspace show --resource-group $apiResourceGroup --workspace-name $workspaceName --query id -o tsv

#1.2 Name your Application Insights Resource.

$insightsName = "appi-$($prefix)-<application-insights-name>"

# 1.0 Check if the extension *application-insights* is installed. If not, install it.

az extension list --output table
az extension add --name application-insights

# 1.3 Create the Application Insights resource

az monitor app-insights component create `
  --app $insightsName `
  --resource-group $apiResourceGroup `
  --location $location `
  --workspace $workspaceId

# If prompted to install the extension *application-insights*, press **y**!

# ---------------------------------------------------------------------------------------------------------------------
## Step 2: Redeploy the Static Web App with the new version

# 2.2 Redeploy your Static Web App, and add the **INSIGHTS_CONNECTION_STRING** Environment Variable. Set its value to be the Connection String you just copied.

$applicationInsightsConStr = "<application-insights-connection-string>"

az staticwebapp appsettings set `
  --name $staticWebName `
  --resource-group $appResourceGroup `
  --setting-names "INSIGHTS_CONNECTION_STRING=$applicationInsightsConStr"
