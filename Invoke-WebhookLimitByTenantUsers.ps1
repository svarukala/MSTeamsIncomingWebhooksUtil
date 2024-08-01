# Authors: Srinivas Varukala
# Description: This script will generate an access token using Oauth 2.0, authorization code flow aka user must login to get the token. This token is for accessing Power Automate service.
<###########################################
This code is provided for the purpose of illustration only and is not intended to be used in a production environment.
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code,
provided that You agree:  to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded;
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded;
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees,
that arise or result from the use or distribution of the this code
###########################################>

clear
# The resource URI
$resource =  "https://service.flow.microsoft.com/"

# Your Client ID and Client Secret obainted when registering your WebApp
$clientid = "******CLIENT ID******";
$clientSecret = "*****CLIENT SECRET******";
$redirectUri = "https://localhost"

# UrlEncode the ClientID and ClientSecret and URL's for special characters 
Add-Type -AssemblyName System.Web
$clientIDEncoded = [System.Web.HttpUtility]::UrlEncode($clientid)
$clientSecretEncoded = [System.Web.HttpUtility]::UrlEncode($clientSecret)
$redirectUriEncoded =  [System.Web.HttpUtility]::UrlEncode($redirectUri)
$resourceEncoded = [System.Web.HttpUtility]::UrlEncode($resource)

# Function to popup Auth Dialog Windows Form
Function Get-AuthCode {
    Add-Type -AssemblyName System.Windows.Forms

    $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=440;Height=640}
    $web  = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width=420;Height=600;Url=($url -f ($Scope -join "%20")) }

    $DocComp  = {
        $Global:uri = $web.Url.AbsoluteUri        
        if ($Global:uri -match "error=[^&]*|code=[^&]*") {$form.Close() }
    }
    $web.ScriptErrorsSuppressed = $true
    $web.Add_DocumentCompleted($DocComp)
    $form.Controls.Add($web)
    $form.Add_Shown({$form.Activate()})
    $form.ShowDialog() | Out-Null

    $queryOutput = [System.Web.HttpUtility]::ParseQueryString($web.Url.Query)
    $output = @{}
    foreach($key in $queryOutput.Keys){
        $output["$key"] = $queryOutput[$key]
    }

    $output
}

# Get AuthCode
$url = "https://login.microsoftonline.com/common/oauth2/authorize?response_type=code&redirect_uri=$redirectUriEncoded&client_id=$clientID&resource=$resourceEncoded&prompt=admin_consent"
Get-AuthCode
# Extract Access token from the returned URI
$regex = '(?<=code=)(.*)(?=&)'
$authCode  = ($uri | Select-string -pattern $regex).Matches[0].Value

#Write-output "Received an authCode, $authCode"

#get Access Token
$body = "grant_type=authorization_code&redirect_uri=$redirectUri&client_id=$clientId&client_secret=$clientSecretEncoded&code=$authCode&resource=$resource"
$tokenResponse = Invoke-RestMethod https://login.microsoftonline.com/common/oauth2/token `
    -Method Post -ContentType "application/x-www-form-urlencoded" `
    -Body $body `
    -ErrorAction STOP

$Tokenresponse.access_token | clip
Write-Host "Access token copied to clipboard"
Write-Host "Here is the access token: $($Tokenresponse.access_token)"


# Invoke web request with authorization header and post body
$webhookPostUrl = "https://prod-94.westus.logic.azure.com:443/workflows/46f32cdb483c40d89081ddfe559dd998/triggers/manual/paths/invoke?api-version=2016-06-01"
$headers = @{
    "Authorization" = "Bearer $($Tokenresponse.access_token)"
    "Content-Type" = "application/json"
}
$body = '{
    "type": "message",
    "attachments": [
        {
            "contentType": "application/vnd.microsoft.card.adaptive",
            "contentUrl": null,
            "content": {
                "`$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                "type": "AdaptiveCard",
                "version": "1.2",
                "body": [
                    {
                        "type": "TextBlock",
                        "text": "Hello there, this message is from secured webhook....."
                    }
                ]
            }
        }
    ]
}'

$response = Invoke-RestMethod -Uri $webhookPostUrl -Method Post -Headers $headers -Body $body
$response


<#
# Below is the equivalent code using Curl.exe on windows. You must replace the ACCESS_TOKEN and the WEBHOOK_URL with your own values

$AuthorizationH = "Authorization: Bearer ***ADD YOUR ACCESS_TOKEN HERE***"

$ContentTypeH = "Content-Type:application/json"

curl.exe -H $ContentTypeH -H $AuthorizationH -d "{
    'type': 'message',
    'attachments': [
        {
            'contentType': 'application/vnd.microsoft.card.adaptive',
            'contentUrl': null,
            'content': {
                '`$schema': 'http://adaptivecards.io/schemas/adaptive-card.json',
                'type': 'AdaptiveCard',
                'version': '1.2',
                'body': [
                    {
                        'type': 'TextBlock',
                        'text': 'Hello there, this is a message from secure webhook'
                    }
                ]
            }
        }
    ]
}" "WEBHOOK_URL"


#>