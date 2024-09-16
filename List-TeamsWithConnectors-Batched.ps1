#requires -version 5.1
#requires -modules Microsoft.Graph.Teams

<#
.SYNOPSIS
  List all the Office 365 connectors that are added to each Microsoft Team in a Microsoft 365 tenant
  This includes incoming webhooks, first-party connectors and third-party connectors

.ROLE
  Recommend an Azure app registration with the following application permissions for least-privilege:
  - Team.ReadBasic.All
  - TeamsAppInstallation.ReadForTeam
  - AppCatalog.Read.All

.EXAMPLE
  PS> Import-Module -Name Microsoft.Graph.Teams
  PS> Connect-MgGraph -ClientId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -TenantId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -CertificateSubjectName 'CN=ConnectorApp'
  PS> .\Get-ConnectorsInstalledInMsTeams.ps1 -DownloadCurrentConnectorList | Export-Csv -Path c:\path\to\TeamsWithConnectors.csv -NoTypeInformation
  Connects to Graph API using an app registration and a certificate with a private key in the current user or computer's certificate store.
  Uses a list of connectors from publicly-accessible endpoints at outlook.office.com.
  Saves the output to a CSV file at c:\path\to\TeamsWithConnectors.csv; does not include information about individual connectors.

.EXAMPLE
  PS> Import-Module -Name Microsoft.Graph.Teams
  PS> Connect-MgGraph -Scopes 'Team.ReadBasic.All','TeamsAppInstallation.ReadForTeam','AppCatalog.Read.All'
  PS> .\Get-ConnectorsInstalledInMsTeams.ps1 -GetConnectorInfo -CustomConnectorGuid 722335e3-d4f0-42a4-8a0b-664ab512115c
  Connects to Graph API with credentials of a signed-in user.
  Uses a static connector list declared in the script and adds a custom connector.
  Outputs directly in the console and includes information about individual connectors and a custom connector in your organization.

.NOTES
  Original authors: Alex Mauclair, Mickael Brest
  Microsoft provides programming examples for illustration only, without warranty either expressed or
  implied, including, but not limited to, the implied warranties of merchantability and/or fitness
  for a particular purpose.

  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
  EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY
  AND/OR FITNESS FOR A PARTICULAR PURPOSE.

  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce
  and distribute the object code form of the Sample Code, provided that You agree:
    (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample
        Code is embedded;
    (ii) to include a valid copyright notice on Your software product in which the Sample Code is
        embedded; and
    (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or
          lawsuits, including attorneys' fees, that arise or result from the use or distribution of
          the Sample Code.

.LINK
  https://github.com/svarukala/MSTeamsIncomingWebhooksUtil/blob/main/List-TeamsWithConnectors.ps1
#>

using namespace System.Collections.Generic
using namespace Microsoft.Graph.PowerShell.Authentication

[CmdletBinding(SupportsShouldProcess)]
Param(

  # GUIDs of custom connectors that you want to include in the search
  [Parameter()]
  [guid[]]$CustomConnectorGuid = @(
    #TODO: add your custom connectors here if you have any
    # 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
    # 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
  ),

  # Additionally retrieves information about connectors found
  [Parameter()]
  [switch]$GetConnectorInfo,

  # Retrieve the current list of all publicly-advertised connectors
  # NOTE: this may retrieve fewer connectors than the static lists provided in the script
  [Parameter()]
  [switch]$DownloadCurrentConnectorList,

  # Maximum number of times the script will retry a batch (or part of a batch) if throttled or an error occurs
  [Parameter()]
  [int]$MaxRetries = 5,

  # Delay in seconds between retries
  [Parameter()]
  [int]$RetryDelaySeconds = 5

)

BEGIN {

  # Check for existing connection to Microsoft Graph
  $context = Get-MgContext
  if($null -eq $context) {
    Write-Warning -Message 'Please connect to Microsoft Graph first: https://github.com/microsoftgraph/msgraph-sdk-powershell/blob/dev/docs/authentication.md'
    exit
  }

  # Warn that delegated permissions aren't the best for this scenario
  if($context.AuthType -eq [AuthenticationType]::Delegated -and
    -not $PSCmdlet.ShouldContinue(
      'When signing in as a user, this script may run longer on account of throttling, and you may not see all Teams in the tenant. Continue?',
      'Running script as a user'
    )) { exit }

  # Download connector lists from outlook.office.com if requested
  [List[guid]]$allConnectors = if($DownloadCurrentConnectorList) {
    try {
      'FirstParty', 'ThirdParty' | ForEach-Object -Process {
        (Invoke-RestMethod -Uri "https://outlook.office.com/connectors/Manage/${_}ConnectorType" -ErrorAction Stop).Id
      }
    }
    catch {
      Write-Warning -Message "Failed to retrieve some of the connectors; using the static list instead"
      $outlookConnectorListDownloadFailed = $true
    }
  }

  # Use a static list of connectors if -DownloadCurrentConnectorList wasn't specified, or if download failed
  if($null -eq $allConnectors -or $outlookConnectorListDownloadFailed) {
    [List[guid]]$allConnectors = @(
      # First-party connectors
      '59a89157-2c61-48b0-8417-4e7d7328561e' # Asana
      'dd63c2fc-4ea3-491a-9e74-fcc31f346478' # Azure DevOps
      '2e29398f-1131-4d94-b79f-9c7aa1cfb672' # Azure DevOps Server
      '1d71218a-92ad-4254-be15-c5ab7a3e4423' # Beeminder
      '6b1a8900-b0d3-4436-99f1-55bcdf2e69bf' # Bitbucket Server
      'ff184ce7-b7ac-47fc-829b-d5c1f6a701ae' # BMC TrueSight Pulse (Boundary)
      'a6fb754a-8cf4-4722-8935-6bf46eab2c61' # Bugsnag
      '3ad346cc-9648-493a-9afd-86dc22cc5692' # Chatra
      '58376fa4-7632-480c-8666-2bb8c87125d8' # CheckMarket
      '40e932e6-6c45-4084-9408-ead4311e9f9d' # Cloud 66
      'aa183fd9-7104-46c4-af9f-9ee9b81d717e' # Cloud Jira
      'd3193953-8111-4e58-a5a5-c1e717604f78' # Crashlytics
      '2f4dc505-8eae-4dad-ad92-c6fed9e4857b' # Datadog
      '462611d2-dc47-455d-b557-7dd65b5e98e1' # Doorbell
      'be91182a-44da-4bb0-8920-d04d0318cf1d' # Enchant
      'e68a6156-c7ca-42c6-b2e2-134ba4b7b887' # Forms
      '37567f93-e2a7-4e2a-ad37-a9160fc62647' # GitHub
      'ca319335-400e-43c1-bca4-b6c745ce3093' # GitHub Enterprise
      '4fcf98ff-e696-44e3-b4df-a6aff076ee1b' # Google Analytics
      '843d0408-1c8c-4c81-ba4f-15235e71c231' # GoSquared
      'a12efe14-52d5-46be-a3ac-cbb5019f2d40' # Help Scout
      '203a1e2c-26cc-47ca-83ae-be98f960b6b2' # Incoming Webhook
      '8fd5dfb8-2fea-4741-bec6-2c7947cbccb2' # Jenkins
      'da4f4b4c-c03b-4918-8afd-ab55045e31e2' # Nevercode
      '081aafe0-930e-4fcd-9f17-c16f41eba4e0' # New Relic
      '95f6081d-4007-4b49-92f0-f68c4ed02c52' # Pingdom
      'b9ab160a-5e2c-40f5-a215-b0c7376ae479' # Promoter
      'c18f658e-c34a-4ee8-ad19-a2cd51e59b71' # RSS
      '3b08b627-1279-4d42-9409-329d321fda94' # Salesforce
      'c7fd4cb3-9662-4ab1-b5a3-47af6e855d34' # SharePoint News
      'b419163b-c31c-4051-b4fa-2956318ed6e2' # StatusPage.io
      'db5e5970-212f-477f-a3fc-2227dc7782bf' # Viva Engage

      # Third-party connectors
      'fa487e65-4457-4d3f-8dac-539ba55d63cd' # Accolader
      '2402bfbb-f952-4a68-aaad-a474daa44412' # Adobe Creative Cloud
      '9bf4c7bb-957e-4c70-bee7-6605185936cd' # air by Impact
      'd681e78c-ed55-41b0-9763-6f10c121b7ee' # Applauz Recognition
      '62452fee-6058-4046-a540-e6e98b179d7a' # AppReviewBot
      '0c42cdbf-56a5-4cdb-ae89-9253cb8138f0' # Attensa
      'e861ca3a-95a8-4371-8a79-45d0fb539fd1' # Avochato
      '01ea66d6-db2b-4ef5-8579-d537c7920d84' # awork
      'a17ee3f7-3f23-4c51-b786-2823ccf82402' # awork
      'c4dfd0ac-c5a1-4a7f-9b3c-07fd634d03b8' # Axure Cloud
      '40733ef5-45e1-44f7-8fae-4a4ac3b23d77' # Axure Share
      'be336790-2421-49fe-83ba-0dc47ff93d08' # Binox
      '150aa1a2-5a7f-45f1-80f9-e0bca1afcbf7' # Biztera
      '79068c5d-c9dc-4911-8c18-62ea4c58b7b3' # Bleemeo
      'fca0933e-9f78-43f4-a9e5-d22cef0db170' # Bucketlist Rewards
      'f630c6de-8abe-4946-9b69-81e95f52b96c' # Bugsnag
      '1faa2d77-3a93-47a4-923f-ce41c118b542' # Canny
      '1d62a1f0-4be5-464e-8eb2-521cc317189c' # Cellip 365 Response Group
      '6881c67c-cc96-4d77-89bc-44012d982b02' # Clever Ads
      '819afdbc-edfb-4f5c-9581-3b87e67fa186' # Clever Google Ads
      '0c8815ec-a561-46ce-b892-13327cf035dc' # ClickUp
      'f269e787-d190-4e8d-9c61-0b8b34998ded' # CLIPr Moment Maker
      '7227585c-8a06-4529-866a-bfea44535f0c' # Cloudbot for Azure
      '512e64c3-f956-441f-95e1-b2f31d4b4872' # Cloudbot for Azure
      'dc5f6d9d-0f8f-4687-b876-787df25aface' # Cloudinspot
      '13610c4a-a361-4979-86af-da32079f5d5a' # CodeFactor
      'a5184531-38ac-4332-8735-4608156c799e' # Complish
      'c3dfff82-5778-4118-adcf-09896593d003' # ContentKing
      '17f34ca7-74b8-4bcf-9292-701e3770b441' # Cronofy Calendar Connector
      '5beef221-9ed5-424c-a853-331be5205908' # Cronycle
      '1c7dc6fd-afc5-4591-a631-a9bc14e1c5b9' # CyReport Dashboard
      '23b22886-bc6f-4b4c-96a1-a707447d8efc' # Datadog
      'fa14b040-e724-4a07-b1d1-f6d6b16baa85' # Dataminr For News
      '1c6f92a8-a6c3-4b1a-bbf9-274b631987a1' # Dataminr Pulse
      '690b3dfd-bc07-4265-b2eb-edffc0d74fa4' # Delighted
      '2b4ebe4e-7500-4aa5-be83-3857bb2bff2e' # Docuo
      '3ae5fd31-fe6e-437e-9abf-06a0821c4baf' # DutyCalls
      '8fea7965-3126-47eb-9cf2-3a37f34cb7b0' # dutycalls.me
      'c6e7dca0-7905-4e68-a643-0f78d157b156' # elmah.io
      'f0513abf-3a1e-4fff-93b6-5566d41ebfe7' # elmah.io
      '260128ec-36bf-49df-956f-7102feba3e49' # enmacc
      '26c1ae44-5054-4b2e-b3f4-750cf0bc5b57' # Flipgrid
      'afb255e6-bf2d-4e04-a4d8-85c345d743b5' # Fond
      '024a37fd-0dcd-453e-bf71-e6509dcca02c' # FormMachines
      'c639d67b-d9e5-4295-a5e0-70a755dabbb1' # Ghost Inspector
      'c136ce50-d352-4184-84b0-2db209df3c54' # Gleap
      'e986e3ae-d7f6-49cf-81d1-a42fa1c80de8' # Google Analytics Insights
      '19a420b1-09f3-4ef0-9e42-6e55e1f677ee' # GuideSpark Communicate Cloud
      '351cffd8-f46e-4902-8e97-2eded45dc41d' # Helpjuice
      '9cb65b00-db92-451b-a9b4-7a783a7d7a13' # Hoopla
      '7b68ceac-8bcc-491d-a140-b00e8d33406b' # HunchBuzz
      'f00d8890-daa8-4c87-89f5-83cbab0bccd4' # iceScrum
      '95197657-b7b5-4404-bd76-143948320f8a' # iLert
      '2858a731-3d1c-4167-9ef6-b910459f44ae' # iLert
      '0ce968b4-ac5e-4718-ae85-861ddabaddbe' # In Case of Crisis
      'a34ce5a7-3719-4f09-aaca-3aa8196e7716' # Inyore
      '4673d4a0-98b1-40b1-8b97-4cd4b19e431a' # Jira Integration Plus Connector
      'e2a69c03-8ba6-4956-8652-b4476ab6135c' # Jira Integration+ Connector
      'd0cfa88f-4a35-4428-8a99-f947c50b1162' # Jira Server
      '566da8c1-7cce-4744-8e10-cf99ed562122' # JustCall
      '94393e32-327e-4870-a185-460a7d01fc95' # Jyre
      '672144dc-c37a-4de1-b4b6-13dadc1f9045' # Kazoo
      '8480345b-e90e-425a-826f-11c06afc8e50' # Kiwi
      '7ab4598a-cc8b-4491-897f-6d8d2a3068e4' # krunch
      '1432b397-0621-4de7-ae82-6bdd52a5b030' # Kudos
      '2d8594a6-150b-408b-93c1-3af31742073d' # Kudos
      '69a5ad6e-e42f-4b25-953b-d88ae96d4aa6' # Leadinfo
      '2c2e60da-f0f3-43b1-9ed9-88f33e81a2c6' # Leapsome
      'd48e7b0f-4089-4ca6-a52c-31b630bb50c9' # Liberty Create
      '0f31e1d3-7037-48fe-a8a0-2355f60fe249' # Maritime Optima
      '83b0e721-a17c-4284-8af3-7ac51418dd86' # Meltwater
      '5a705511-a760-4134-91c7-52ac47285f4a' # MindMeister
      '4c53389c-6fe0-4d8c-8d94-bf27536cf93e' # Motivosity
      'a2cbe646-4fdf-40bf-a393-056e3d554787' # NewsWhip Spike
      'b3fef7e7-c1c8-40e5-aeb7-8e002c0ff565' # NimbleWork
      '6a222c37-3c77-4732-a139-f9ad59df4695' # Nuclino
      '74d74206-0183-401d-932e-315f5021fdb1' # Package Notifier
      '41d75dd1-cda0-4b7b-b82b-30aa279cbdf8' # Parsable
      '1f611cc4-7e5a-4efb-a34d-d52c5239a69f' # PerkSweet
      '03a7b012-0d31-4399-a0a2-87ef279a866d' # Plenion
      'fbef0cb3-ede6-4e4e-a7c9-32fe519c9ef5' # POEditor
      'd4f4035c-509d-417c-834e-be824a8c8780' # PostBeyond
      '90381cb0-998f-4ba3-9699-130201de5ddb' # Power BI Collaboration
      'd2109931-ee39-4ad2-9096-65e09e329424' # Preciate
      '9880fa29-05bf-44f0-8fed-c5615ec8bb97' # Preciate Recognition
      '80051254-9836-4247-8ce8-7b347eb0da54' # Priority Matrix
      '256e5166-0ac6-4803-93b2-6ab29001f6ee' # Projectplace
      '1dae9327-c000-4337-9b6b-96628106de7a' # Qooper
      '76787555-66f7-4b6e-9e1e-2bc81d58fec1' # QuandaGo Collaborative Case Management
      '5c78f880-ea6a-4928-b381-6079609b26b0' # Recognize
      'a192c62b-7f1b-4782-874e-409df8ac7d6a' # RevDeBug Notification Agent
      '09476849-fc90-4f46-a71f-75171b99adb8' # Revelation helpdesk
      '61a2c0f4-b0e8-40ae-85d6-aacd33fa9349' # Sales Canvas
      '9e29f54b-3046-4e00-9879-b9dad81e70af' # Scytec DataXchange
      '32a5e6c4-c9dd-4c12-89a8-34d2c496312f' # SignalFx
      'e214eaf2-c340-4462-9f44-e4560de816f4' # SignalFx Events
      '92afefb8-8032-4533-bad0-50b13ca1dffa' # Simple In/Out
      '9ce8b7b7-4435-4edb-9c6f-205a9efe944d' # Site24x7
      '0dbeae52-26ee-45f2-866e-6bdc4b46069f' # SmartDB
      'aca450e0-6c04-40ce-8522-350072069dd9' # Smartnotation
      '6d500e7a-f01d-4427-8285-748a0d8caeb0' # SmileBack
      'afe63f50-aadc-4139-82dc-ba8da6270be9' # Sociabble
      'cfe2111f-b7de-4a0c-a2a5-0a164260bdb0' # Staffbase News
      'e21a393e-21a2-420c-892b-3d9e35d81c52' # Summize Assistant
      'f15bf13c-60e2-4ad2-93da-4fee046b5e98' # SuperOffice
      '0fd925a0-357f-4d25-8456-b3022aaa41a9' # SurveyMonkey
      'ca3c80a0-5d82-4e58-80fb-af1e35dd6bff' # SwiftKanban
      '5293bad8-e12e-4675-b9ec-0f1f1396243f' # TackleBox
      '98d0093e-2769-4d7b-ba31-2671aa7e097b' # Tap My Back
      'e17958d2-d13a-447c-b700-93d1353bf424' # TeamConnect for OrderCloud
      'a87fd06b-7e73-4374-ba75-4545b2470706' # TeamConnect for Sitecore
      'c12d74aa-d55e-4638-9829-fcefcbeb2971' # TeamViewer Remote Management
      'f3bf8627-aed2-4ba4-a76d-8ed3ffa3f555' # Thanks
      '28c4d7d8-09da-46f3-a831-1a3b0016ba61' # TINYpulse
      'b39a7048-cb43-4bf0-8e8b-b8efc149fa47' # Tugboat Logic
      'e57863b4-ee70-4699-9028-be2b24b85f19' # Uptale
      'fabbb7b2-b394-49b5-b612-2862d5e6b1d9' # UserVoice
      '319521d4-c081-48c4-b44c-54372f09d930' # Vantage Rewards
      'cf2e56b0-2449-4042-b4f5-2bc78e2d3288' # Ybug
      'd7ab8793-bb60-4f92-adf0-efb868152466' # YouScan
      'ad306cd4-1e98-4c46-8833-611a714fddba' # Zabbix Webhook
      '708eb342-66c5-4c5f-986a-9a6c1772243e' # Zenduty
      '1558b099-53e9-4804-bd3a-21e5e4a36857' # Zenkit
      'a8735974-bf4e-45f0-807e-f4c07c9c6826' # Zeplin
      '16b44061-d239-4ff2-96fa-3705551c814d' # Zoho Desk
    )
  }

  # Add custom connectors to the list if provided
  if($CustomConnectorGuid) { $allConnectors.AddRange($CustomConnectorGuid) }

  'Will search for {0} Teams apps that are considered Office 365 Connectors' -f $allConnectors.Count | Write-Verbose

  # Create a filter for the Graph API command to only return connector apps
  $onlyFindConnectorsFilter = "teamsApp/id in ('{0}')" -f ($allConnectors -join "','")
  # NOTE: with the static filter list, the final Graph API URL to get a Team's installed apps is 6,300+
  # characters long. Graph API has a limit of 8,192 characters for a URL, so we're well within that limit.
  # However, if you add more than 40 custom connectors, you will run into that limit. The workaround is to
  # POST to $batch instead of using the Get-MgTeamInstalledApp cmdlet later in the script.

  # Warn that doing an expansion will take longer
  if($GetConnectorInfo -and
    -not $PSCmdlet.ShouldContinue(
      'This will retrieve detailed information about each connector found, which will significantly increase the time it takes to run this script. Continue?',
      'Retrieving connector details'
    )) { exit }

}

PROCESS {

  # All $batch calls will use these parameters as a baseline
  $batch = @{
    Method     = 'POST'
    Uri        = 'v1.0/$batch'
    Body       = @{ requests = [List[hashtable]]::new() }
    OutputType = 'PSObject'
  }

  'Retrieving all Teams in the tenant; this may take a while' | Write-Verbose
  $teams = Get-MgTeam -All -Property DisplayName, Id

  foreach($team in $teams) {

    $progress = @{
      Id               = 1
      Activity         = 'Evaluating Microsoft Teams for webhook-based connectors'
      Status           = 'Adding Teams to the batch'
      CurrentOperation = $team.DisplayName
      PercentComplete  = (($teams.IndexOf($team) + 1) / $teams.Count * 100)
    }
    Write-Progress @progress

    # https://learn.microsoft.com/graph/api/team-list-installedapps
    $getTeamInstalledAppCommand = '/teams/{0}/installedApps?$filter=' + $onlyFindConnectorsFilter

    # Only expand the connector info if requested, which will take a lot longer
    if($GetConnectorInfo) { $getTeamInstalledAppCommand += '&$expand=teamsAppDefinition($select=teamsAppId,displayName,shortDescription)' }

    $batch.Body.requests.Add(@{
        # By setting the request ID to the same index position, the response can be quickly matched to the list of Teams
        # Otherwise, there would be a slow/expensive Where-Object call to find the Team in the list
        id     = $teams.IndexOf($team)
        method = 'GET'
        url    = ($getTeamInstalledAppCommand -f $team.Id)
      }
    )

    # Start evaluating the batch when the requests array reaches 20 Teams or if this is the last Team
    if($batch.Body.requests.Count -eq 20 -or ($teams.IndexOf($team) -eq $teams.Count - 1)) {

      # Helps out with the retry logic
      $finished   = $false
      $retryCount = 0

      [List[PSCustomObject]]$batchResponses = do {

        $progress.Status           = 'Processing current batch of Teams'
        $progress.CurrentOperation = '{0} remaining' -f $batch.Body.requests.Count
        Write-Progress @progress

        # Reset the clock for retry/throttling mitigation
        $waitSeconds = 0

        # Run the batch command
        try   { $batchResult = Invoke-MgGraphRequest @batch -ErrorAction Stop }
        catch {
          if($retryCount -lt $MaxRetries) { $waitSeconds = $RetryDelaySeconds }
          'Error calling $batch directly: {0}' -f $_.Exception.Message | Write-Warning
        }

        foreach($response in $batchResult.responses) {

          # Consider the following scenario:
          # - Team 1's response includes an @odata.nextLink (more connectors than Graph wanted to put in a single response)
          # - Team 2's response is throttled and adds {retry-after} seconds to $waitSeconds
          # - The check for $waitSeconds towards the end of the do loop iterates $retryCount
          # - The next $batch includes a paging request *and* a throttle request
          # If $batch needs to retry responses based on throttling or errors, no big deal - just iterate $retryCount and move on
          # However, we don't want to "charge" a retry for the legitimate paging request, especially if there are more pages than $MaxRetries
          # So if $paging is set to $true, there then we won't iterate $retryCount if other responses are throttling or errors
          # ...this logic is kinda useless for this script (who has >100 installed Teams connectors?) but it's here for completeness
          $paging = $false

          # Handle individual responses based on HTTP status code
          switch($response.status) {

            # If things went fine
            200 {
              # Add a property to the response that tracks the index of the Team in the original list
              $response.body | Add-Member -MemberType NoteProperty -Name teamIndex -Value $response.id

              # Output the response (will be stored in $batchResponses)
              $response.body

              # Remove the request from the batch (don't need to retry it)
              $originalRequest = $batch.Body.requests.Where({ $_.id -eq $response.id })[0]
              $null = $batch.Body.requests.Remove($originalRequest)

              # Pagination: if there are more results, add the nextLink to the batch
              # ...but only if additional connector info was requested - no need to page if we know a Team has at least one connector
              if(-not [string]::IsNullOrEmpty($response.'@odata.nextLink') -and $GetConnectorInfo) {
                $paging = $true
                $batch.Body.requests.Add(@{
                    # Keep the same request ID so we can still match the response to the Team
                    id     = $response.id
                    method = 'GET'
                    url    = $response.'@odata.nextLink'
                  }
                )
              }
            }

            # If a response was throttled, look for retry-after
            429 { $waitSeconds += $response.headers['Retry-After'] }

            # For any other HTTP error, add the default delay
            default { $waitSeconds += $RetryDelaySeconds }

          }

        }

        # Escape the loop if we hit max retries
        if($retryCount -eq $MaxRetries) {
          'Max retries reached, skipping {0} Teams in this batch' -f $batch.Body.requests.Count | Write-Warning
          break
        }

        # Sleep if we were throttled or saw some other HTTP error
        elseif($waitSeconds -gt 0) {

          $finished = $false
          if(-not $paging) { $retryCount++ }

          '[{0}/{1} retries] Waiting {2} seconds to retry {3} requests in this batch' -f
            $retryCount, $MaxRetries, $waitSeconds, $batch.Body.requests.Count | Write-Warning

          Start-Sleep -Seconds $waitSeconds

        }

        # Loop *should* be complete if there are no more requests to process...
        elseif($batch.Body.requests.Count -eq 0) {
          $finished = $true
        }

      } until($finished)

      foreach($batchResponse in $batchResponses) {

        $teamApps = $batchResponse.value
        $teamInfo = if($teamApps.Count -eq 0) { $null }
        else {
          # This is so much faster than Where-Object or even LINQ
          $responseTeam = $teams[$batchResponse.teamIndex]
          [ordered]@{
            TeamName = $responseTeam.DisplayName
            TeamId   = $responseTeam.Id
          }
        }

        # Output the Team's information
        if($teamInfo) {

          # Output a row for each application installed in the Team if connector info was requested
          if($GetConnectorInfo) {
            foreach($app in $teamApps.TeamsAppDefinition) {
              [PSCustomObject]($teamInfo + [ordered]@{
                  AppId          = $app.TeamsAppId
                  AppName        = $app.DisplayName
                  AppDescription = $app.ShortDescription
                }
              )
            }
          }

          # Output a row for each Team that has connectors installed if connector info wasn't requested
          else {
            [PSCustomObject]$teamInfo
          }

        }

      }
    }
  }
}