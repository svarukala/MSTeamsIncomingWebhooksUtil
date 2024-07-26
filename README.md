# MS Teams IncomingWebhooks Util

This repo has two script options and a 3rd option using Purview Audit log search.

Option 1: **List-TeamsWithConenctors.ps1**

This script is comprehensive as it outputs all the connectors (including incoming webhooks, 1st and 3rd party connectors) used in all the Teams in your Tenant. And this script can by run by the global admin and doesnt need any additional setup requirements.

Below GUID can be used to filter the spreadsheet to limit the results to Incoming Webhooks
203a1e2c-26cc-47ca-83ae-be98f960b6b2



Option 2: **List-IncomingWebhooks.ps1**

Enumerates the Teams that are using incoming webhooks. This sample script is using Client ID and Secret and runs in the application context. You must follow below steps as pre-requisites to run the script.

    # Steps 1
    1. Register Entra App ID. While registering the app:
        * Provide Name
        * Selet Accounts in this org directory only (Single Tenant)
        * Rediret URI - empty
    2. Gather the Tenant Id, Client Id, Client Secret
    3. Ensure below application permissions are added and admin consent granted.
        * Group.Read.All
        * TeamsAppInstallation.Read.All

    # Step 2
    1. Update the script with the Tenant Id, Client id, and Client Secret.
    2. Run the script

    # Output
    You can see the sample output file in this repository. 

Option 3: Purview

Follow steps listed in List-ConenctorsUsingPurview.md file.