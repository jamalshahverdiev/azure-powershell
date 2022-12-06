function Export-EnvironmentDatabases($resourceGroupName, $serverDatabaseLookups, $sourceEnvironment, $containerName, $storageName, $storageKey, $backupNamePrefix, $administratorLogin, $administratorPassword) {
                
                $jobs=@()
                                
                $serverDatabaseLookups.Keys | %{ 
                                $sourceServer = $_
                                $databases = $serverDatabaseLookups[$_]          
                                
                                Write-Host "Beginning Export databases from $sourceServer ($sourceEnvironment)" -f gray
                                
                                $databases | %{
                                                $baseDatabaseName = $_
                                                
                                                $jobs += start-job -scriptblock {
                                                                param($scriptDir, $resourceGroupName, $sourceServer, $baseDatabaseName, $serviceUserName, $serviceUserPassword, $tenantId, $subscriptionId, $containerName, $storageName, $storageKey, $sourceEnvironment, $backupNamePrefix, $administratorLogin, $administratorPassword)
                                                
                                                                $sourceDatabase = "$($sourceEnvironment)_$($baseDatabaseName)"
                                                
                                                                $pword = ConvertTo-SecureString -String $serviceUserPassword -AsPlainText -Force
                                                                $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $serviceUserName, $pword
                                                                Add-AzureRmAccount -Credential $credential -ServicePrincipal -tenantId $tenantId -subscriptionId $subscriptionId | Out-Null
                                                                
                                                                $pword = ConvertTo-SecureString -String $administratorPassword -AsPlainText -Force
                                                                $storageContext = New-AzureStorageContext -StorageAccountName $StorageName -StorageAccountKey $StorageKey
                                                                
                                                                if ($sourceServer -match "cddb") {
                                                                                $backupDatabaseFile = "Temp_${baseDatabaseName}_Delivery.bacpac"
                                                                                $finalBackupDatabaseFile = "${baseDatabaseName}_Delivery.bacpac"
                                                                } elseif ($sourceServer -match "cmdb") {
                                                                                $backupDatabaseFile = "Temp_${baseDatabaseName}_Authoring.bacpac"
                                                                                $finalBackupDatabaseFile = "${baseDatabaseName}_Authoring.bacpac"
                                                                } else {
                                                                                $backupDatabaseFile = "Temp_${baseDatabaseName}.bacpac"
                                                                                $finalBackupDatabaseFile = "${baseDatabaseName}.bacpac"
                                                                }
                                                                
                                                                Get-AzureStorageBlob -Container $containerName -Context $storageContext -prefix "$finalBackupDatabaseFile" | `
                                                                                ?{$_.Name -ne "$finalBackupDatabaseFile"} | `
                                                                                Sort-Object name -descending | `
                                                                                select -skip 2 | %{ `
                                                                                Remove-AzureStorageBlob -Container $containerName -Context $storageContext -blob $_.name }
                                                                
                                                                $blob = Get-AzureStorageBlob -Container $containerName -Context $storageContext -blob $backupDatabaseFile -errorAction Silentlycontinue
                                                                if ($blob) {
                                                                                write-host "Delete temp file $backupDatabaseFile" -f gray
                                                                                Remove-AzureStorageBlob -Container $containerName -Context $storageContext -blob $backupDatabaseFile
                                                                }
                                                                
                                                                # Export to temporary location
                                                                Write-Host "Start export $sourceServer/$sourceDatabase to $backupDatabaseFile" -f gray                                                       
                                                                $exportRequest = New-AzureRmSqlDatabaseExport -ResourceGroupName $resourceGroupName `
                                                                                                -ServerName $sourceServer `
                                                                                                -DatabaseName $sourceDatabase  `
                                                                                                -StorageKeyType "StorageAccessKey" `
                                                                                                -StorageKey $storageKey `
                                                                                                -StorageUri "http://$($StorageName).blob.core.windows.net/$($ContainerName)/$($backupDatabaseFile)" `
                                                                                                -AdministratorLogin $administratorLogin `
                                                                                                -AdministratorLoginPassword $pword
                                                                
                                                                $lastStatus = $null
                                                                do {
                                                                                sleep 10
                                                                                $statusInfo = $exportRequest | Get-AzureRmSqlDatabaseImportExportStatus
                                                                                if ($statusInfo.Status -ne $lastStatus) {
                                                                                                write-host "$sourceDatabase status - $($statusInfo.Status) $($statusInfo.StatusMessage)" -f gray
                                                                                                $lastStatus = $statusInfo.Status
                                                                                }
                                                                } while (!$statusInfo -or !($statusInfo.status -match "Succeeded" -or $statusInfo.status -match "Error" -or $statusInfo.status -match "Fail"))
                                                                                
                                                                # Archive previous backup           
                                                                $blob = Get-AzureStorageBlob -Container $containerName -Context $storageContext -blob $finalBackupDatabaseFile -errorAction Silentlycontinue
                                                                if ($blob) {
                                                                                write-host "Archive backup file $finalBackupDatabaseFile" -f gray

                                                                                $modifiedDateObj = Get-Date -date $blob.ICloudBlob.Properties.LastModified.UtcDateTime
                                                                                $modifiedDate = $modifiedDateObj.ToString("yyyyMMddHmm")
                                                                                
                                                                                $archiveBlobName = $finalBackupDatabaseFile.Replace(".", "_$($modifiedDate).")
                                                                                $blob = Start-AzureStorageBlobCopy -SrcContainer $containerName `
                                                                                                -SrcBlob $finalBackupDatabaseFile `
                                                                                                -SrcContext $storageContext `
                                                                                                -DestContainer $containerName `
                                                                                                -DestBlob $archiveBlobName `
                                                                                                -DestContext $storageContext
                                                                                
                                                                                do {
                                                                                                $status = ($blob | Get-AzureStorageBlobCopyState)
                                                                                                write-host "Waiting for copy of $fileName package on Azure $($status.Status)" -f gray
                                                                                } while ($status.Status -ne "Success")
                                                                                
                                                                                Remove-AzureStorageBlob -Container $containerName -Context $storageContext -blob $finalBackupDatabaseFile
                                                                }
                                                                
                                                                # Rename this backup to live
                                                                write-host "Rename $backupDatabaseFile to $finalBackupDatabaseFile"
                                                                $blob = Start-AzureStorageBlobCopy -SrcContainer $containerName `
                                                                                                -SrcBlob $backupDatabaseFile `
                                                                                                -SrcContext $storageContext `
                                                                                                -DestContainer $containerName `
                                                                                                -DestBlob $finalBackupDatabaseFile `
                                                                                                -DestContext $storageContext

                                                                do {
                                                                                $status = ($blob | Get-AzureStorageBlobCopyState)
                                                                                write-host "Waiting for copy of $fileName package on Azure $($status.Status)" -f gray
                                                                } while ($status.Status -ne "Success")
                                                                                                                
                                                                # Delete temp backup file
                                                                $blob = Get-AzureStorageBlob -Container $containerName -Context $storageContext -blob $backupDatabaseFile -errorAction Silentlycontinue
                                                                if ($blob) {
                                                                                write-host "Delete temp file $backupDatabaseFile" -f gray
                                                                                Remove-AzureStorageBlob -Container $containerName -Context $storageContext -blob $backupDatabaseFile
                                                                }                              
                                                                                                
                                                                Write-Host "$sourceDatabase - Completed export" -f gray             
                                                                                
                                                } -ArgumentList @($scriptDir, $resourceGroupName, $sourceServer, $baseDatabaseName, $serviceUserName, $serviceUserPassword, $tenantId, $subscriptionId, $containerName, $storageName, $storageKey, $sourceEnvironment, $backupNamePrefix, $administratorLogin, $administratorPassword)
                                }
                }
                
                Wait-ForJobs $jobs "Wait for database export"
}
