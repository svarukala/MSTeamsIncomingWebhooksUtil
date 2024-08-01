# MS Teams IncomingWebhooks Util

This repo has two script options and a 3rd option using Purview Audit log search.

## Option 1: **List-TeamsWithConenctors.ps1**

This script is comprehensive as it outputs all the connectors (including incoming webhooks, 1st and 3rd party connectors) used in all the Teams in your Tenant. And this script can by run by the global admin and doesnt need any additional setup requirements.

Below GUID can be used to filter the **Add On Guid** column in the csv/spreadsheet to limit the results to Incoming Webhooks
203a1e2c-26cc-47ca-83ae-be98f960b6b2



## Option 2: **List-IncomingWebhooks.ps1**

Enumerates the Teams that are using incoming webhooks. This sample script is using Client ID and Secret and runs in the application context. You must follow below steps as pre-requisites to run the script.

#### Steps 1
1. Navigate to Azure Portal: https://portal.azure.com. Search for "Entra ID" and open it.

    ![alt text](Images/Open-entraid.png)

2. Open **App registrations** under **Manage** in the left nav.

    ![alt text](Images/Open-appreg.png)

3. Click **+ New registration** to register a new Entra App. While registering the app:
    * Provide Name
    * Selet Accounts in this org directory only (Single Tenant)
    * Rediret URI - empty

    ![alt text](Images/Reg-app.png)

4. Gather the Tenant Id, Client Id

    ![alt text](Images/Tid-Cid.png)

5. Create Client Secret by navigating to **Certificates & secrets** under **Manage**

    ![alt text](Images/Create-secret.png)

    ![alt text](Images/Add-secret.png)

6. Copy the secret
    
    ![alt text](Images/Copy-secret.png)

7. Navigate to **API permissions** under **Manage**. Click **+ Add a permission**. In the pop-up select **Microsoft Graph**. Then select **Application permissions** block. 

8. Ensure below application permissions are added
    * Group.Read.All
    * TeamsAppInstallation.Read.All

9. Click on **Grant admin consent...** button to grant the selected permissions

    ![alt text](Images/Graph-perms.png)
    
    NOTE: If you do not grant admin consent, the access token fetched will not have the right scopes and the graph query will results in a 403 error.

#### Step 2
1. Update the script with the Tenant Id, Client id, and Client Secret.
2. Run the script

#### Output
You can see the sample output file in this repository. 

## Option 3: Purview

Follow steps listed in List-ConenctorsUsingPurview.md file.



# How to invoke incoming webhooks in Power Automate Flow that is limited to Tenant users only or a subsset of users

1. Once you create the incoming webhook with the trigger **When a Teams webhook request is received**. You will seee that you can limit the webhook to be triggered by users belonging to your tenant only. You can even specify a subset of users.
    ![alt text](Images/Secured-webhook.png)
2. To invoke this webhook request you must have an auhtorization header with bearer token aka access token.
3. To get an access token, you must have an Entra ID app registration and go through the OAuth2.0 authorization code flow. 
4. You can follow the same steps (until Step 6) as described above in Option 2 to create an Entra ID App registration. There is one minor change in Step 3. You must provide a redirect URL as https://localhost
    ![alt text](Images/New-AppRedUrl.png)
5. Then navigate to **API permissions**, Click **+ Add a permission** button.
6. Under **Microsoft APIs** select **Power Automate**
    ![alt text](Images/Perm-PA.png)
7. Then select **Delegated permissions** and select **User**
    ![alt text](Images/Add-PAUserRole.png)
8. Finally Grand admin consent
    ![alt text](Images/Admin-consent.png)
5. Once you have this information, you can plug that into Invoke-WebhookLimitByTenantUsers.ps1 script to call the webhook securely. You will see the permissions concent dialog while going through the oauth2.0 process. Click Accept.
    ![alt text](Images/Consent-perms.png)




