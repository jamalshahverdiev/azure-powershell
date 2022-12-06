Param(
    [string] $servername
)

Import-AzureRmContext -path (Get-ChildItem .\AvanadeCredentials.json).FullName
New-AzureRmResourceGroup -Name 'sqlRG' -Location $ResourceGroupLocation
New-AzureRmStorageAccount -ResourceGroupName 'sqlRG' -AccountName 'scstbackupsql' -Location $ResourceGroupLocation  -SkuName "Standard_LRS" -Kind Storage
$accountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName 'sqlRG' -Name 'scstbackupsql').Value[0]
$context = New-AzureStorageContext -StorageAccountName 'scstbackupsql' -StorageAccountKey $accountKey 
New-AzureStorageContainer -Name 'scstbackupcontainer' -Context $context -Permission Container

foreach ( $index in $dbNameArray ) {
    $exportRequest = New-AzureRmSqlDatabaseExport -ResourceGroupName $ResourceGroupName `
        -ServerName $servername.Split('.')[0] `
        -DatabaseName $index `
        -StorageKeyType "StorageAccessKey" `
        -StorageKey $accountKey `
        -StorageUri "https://scstbackupsql.blob.core.windows.net/scstbackupcontainer/$index.bacpac" `
        -AdministratorLogin "$sqlAdminLogin" `
        -AdministratorLoginPassword $pwd

    $lastStatus = $null
    do {
        Start-Sleep 10
        $statusInfo = $exportRequest | Get-AzureRmSqlDatabaseImportExportStatus
        if ($statusInfo.Status -ne $lastStatus) {
            write-host "$index status - $($statusInfo.Status) $($statusInfo.StatusMessage)" -f gray
            $lastStatus = $statusInfo.Status
        }
    } while (!$statusInfo -or !($statusInfo.status -match "Succeeded" -or $statusInfo.status -match "Error" -or $statusInfo.status -match "Fail"))
}