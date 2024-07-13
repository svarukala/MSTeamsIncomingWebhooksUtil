# Use Purview Portal to search audit logs and identify the Connectors added to Teams.


You can search Purview Portal > Audit Logs for below activities to identify existing Connectors in Teams/Channels. 
* ConnectorAdded
* UpdatedConnector

A few things to consider:
* The advantage with this approach is that it also provides the Channel to which the connector was added. 
* Audit logs are retained for 1 Year for those with E5 license.
* Audit logs are retained for 180 days for any other non-E5 license.
* The default retention period for Audit (Standard) has changed from 90 days to 180 days. Audit (Standard) logs generated before October 17, 2023 are retained for 90 days. Audit (Standard) logs generated on or after October 17, 2023 follow the new default retention of 180 days.


Below is a sample PowerShell query using Exchange Online PowerShell Module's Search-UnifiedAuditLog commandlet.
```powershell
Connect-ExchangeOnline -UserPrincipalName admin@contoso.onmicrosoft.com
Search-UnifiedAuditLog -StartDate 7/01/2024 -EndDate 7/11/2024 -Operations ConnectorAdded -SessionCommand ReturnLargeSet
```

Note: By default, this cmdlet returns a subset of results containing up to 100 records. Use SessionCommand parameter with the ReturnLargeSet value to exhaustively search up to 50,000 results. The SessionCommand parameter causes the cmdlet to return unsorted data.


**References**
* https://learn.microsoft.com/en-us/purview/audit-log-activities#microsoft-teams-activities
* https://learn.microsoft.com/en-us/purview/audit-search?tabs=microsoft-purview-portal
