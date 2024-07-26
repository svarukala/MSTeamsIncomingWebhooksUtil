## Use Purview Audit Log Search

You can search Purview Portal > Audit Logs for below activities to identify existing Connectors in Teams/Channels. 
1.  ConnectorAdded
2. UpdatedConnector

A few things to consider:
1. The advantage with this approach is that it also provides the Channel to which the connector was added. 
2. Audit logs are retained for 1 Year for those with E5 license.
3. Audit logs are retained for 180 days for any other non-E5 license. 
4. The default retention period for Audit (Standard) has changed from 90 days to 180 days. Audit (Standard) logs generated before October 17, 2023 are retained for 90 days. Audit (Standard) logs generated on or after October 17, 2023 follow the new default retention of 180 days.

Below is a sample PowerShell query using Exchange Online PowerShell Module's Search-UnifiedAuditLog commandlet.

```powershell
Connect-ExchangeOnline -UserPrincipalName admin@contoso.onmicrosoft.com

Search-UnifiedAuditLog -StartDate 7/01/2024 -EndDate 7/11/2024 -Operations ConnectorAdded -SessionCommand ReturnLargeSet
```

```
Note: By default, this cmdlet returns a subset of results containing up to 100 records. Use SessionCommand parameter with the ReturnLargeSet value to exhaustively search up to 50,000 results. The SessionCommand parameter causes the cmdlet to return unsorted data.
```

The CSV report generated using the above method contains a JSON formatted column header **"AuditData"** that contains a lot of useful information including Team name/id, Channel name etc. 

You can split the "AuditData" column by opening the CSV file in Excel. Follow below instructions:
1. Open the CSV in Excel.
2. Select the column in excel.
3. Go to the Data tab and select From Table/Range. Excel will ask if your data has headers. Click OK. That opens the Power Query editor. 
4. Switch to Transform tab, Within the Text column group, select Parse > JSON
5. That coverts each entry into a record item.
6. Click the expand icon (the two arrows pointing outward) in the header of this column. 
7. Select the fields you want to expand and click OK.


Alternately, use below PowerShell to expand that column and save to a new file with the expanded columns:

```powershell
# Path to the CSV file
$csvFilePath = "**PATH TO YOUR CSV**"

# Import the CSV file
$csvData = Import-Csv -Path $csvFilePath

# Define a script block to expand JSON columns
$expandJsonColumns = {
    $jsonColumnName = "AuditData" 
    $expandedData = @()

    foreach ($row in $csvData) {
        $jsonData = $row.$jsonColumnName | ConvertFrom-Json
        $newRow = $row.PSObject.Copy()
        $jsonData.PSObject.Properties | ForEach-Object {
            $newRow | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value -Force
        }
        $expandedData += $newRow
    }
    $expandedData
}

# Expand JSON columns
$expandedData = & $expandJsonColumns

# Export the expanded data to a new CSV file
$expandedData | Export-Csv -Path "C:\path\to\your\expanded_file.csv" -NoTypeInformation
```