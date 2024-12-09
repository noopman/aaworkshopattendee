# Exercise 1

In this exercise you will deploy an **Azure Application Insights** resource that will monitor your Web Application. offering logs about users, sessions, events and more.

## Estimated time: TODO minutes

## Learning objectives

- Use Azure Application Insights for Web App monitoring.

## Prerequisites

To begin this module you will need the Azure resources that you deployed in the previous modules.

During this module you will also need the following PowerShell variables used previously:

- $location - location of the first region deployed in Module 0.
- $apiResourceGroup  - name of your API Resource Group deployed in Module 1.
- $staticWebName - name of your Azure Static Web App resource.
- $gameContainerUrl - url of your Game API container.
- $apimUrl - endpoint for your Azure API Management resource(Gateway URL).

## Step 1: Deploy an Azure Application Insights resource

### 1.1 Deploy a Log Analytics Workspace Resource and save its ID

To use an Application Insights resource, it is recommended to link it to a Log Analytics Workspace. You can also deploy a standalone Application Insights, but it's deprecated and not available on some regions. You will deploy a Log Analytics Workspace so you won't have any issues with this exercise.

### 1.2 Name your Application Insights Resource

### 1.3 Create the Application Insights resource

> [!IMPORTANT]
> If prompted to install the extension *application-insights*, press **y**.

## Step 2: Redeploy the Static Web App with the new version

Now you will need to redeploy the Web App with the new code to communicate with the Application Insights resource.

### 2.1 Reconfigure the deployment workflow

To deploy the version of the app with the Application Insights functionality, you need to change the deployment workflow under `./github/workflows`, more exactly, you have to change

| Variable | New value |
| -- | -- |
| app_location | /module-8-observability-and-monitoring/Exercise_1/RockPaperScissors |
| api_location | /module-8-observability-and-monitoring/Exercise_1/RockPaperScissorsAPI |

### 2.2 Redeploy your Static Web App with the **INSIGHTS_CONNECTION_STRING** Environment Variable

Copy the Connection String of your Application Insights resource. It is located in the [Azure portal](https://portal.azure.com) on the newly created Application Insights resource. On the **Overview** tab next to **Connection String**.

## Step 3: Test the application and check Application Insights for events

When you play the game it should automatically record events in Application Insights. The data is stored in the log analytics workspace you created.

Open the [Azure portal](https://portal.azure.com) and navigate to your Application Insights Resource. Check the usage of the application, under the Usage tab. You see the number of users of your application, and events about how they use the app, which pages they access etc.
