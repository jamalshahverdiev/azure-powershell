# Login-AzureRmAccount
# Set the resource group name and location for your source server
$sourceresourcegroupname = "sitecoreRG"
$sourcelocation = "westeurope"
# Set the resource group name and location for your target server
$targetresourcegroupname = "sitecoreRG"
$targetlocation = "westeurope"
# Set an admin login and password for your server
$adminlogin = "sitecoreAdmin"
$password = "SiteC0re@dminl0g!n"
# The logical server names have to be unique in the system
$sourceservername = "oldstcoresqlsrv.database.windows.net"
$targetservername = "oldstcoresqlsrv.database.windows.net"
# The sample database name
$sourcedatabasename = "st_core"
$targetdatabasename = "st_core_test"
# The ip address range that you want to allow to access your servers
$sourcestartip = "0.0.0.0"
$sourceendip = "0.0.0.0"
$targetstartip = "0.0.0.0"
$targetendip = "0.0.0.0"

# Create two new resource groups
$sourceresourcegroup = New-AzureRmResourceGroup -Name $sourceresourcegroupname -Location $sourcelocation
$targetresourcegroup = New-AzureRmResourceGroup -Name $targetresourcegroupname -Location $targetlocation

# Create a server with a system wide unique server name
$sourceresourcegroup = New-AzureRmSqlServer -ResourceGroupName $sourceresourcegroupname `
    -ServerName $sourceservername `
    -Location $sourcelocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
$targetresourcegroup = New-AzureRmSqlServer -ResourceGroupName $targetresourcegroupname `
    -ServerName $targetservername `
    -Location $targetlocation `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminlogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
$sourceserverfirewallrule = New-AzureRmSqlServerFirewallRule -ResourceGroupName $sourceresourcegroupname `
    -ServerName $sourceservername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $sourcestartip -EndIpAddress $sourceendip
$targetserverfirewallrule = New-AzureRmSqlServerFirewallRule -ResourceGroupName $targetresourcegroupname `
    -ServerName $targetservername `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $targetstartip -EndIpAddress $targetendip

# Create a blank database in the source-server with an S0 performance level
$sourcedatabase = New-AzureRmSqlDatabase  -ResourceGroupName $sourceresourcegroupname `
    -ServerName $sourceservername `
    -DatabaseName $sourcedatabasename -RequestedServiceObjectiveName "S0"

# Copy source database to the target server 
$databasecopy = New-AzureRmSqlDatabaseCopy -ResourceGroupName $sourceresourcegroupname `
    -ServerName $sourceservername `
    -DatabaseName $sourcedatabasename `
    -CopyResourceGroupName $targetresourcegroupname `
    -CopyServerName $targetservername `
    -CopyDatabaseName $targetdatabasename 

# Clean up deployment 
# Remove-AzureRmResourceGroup -ResourceGroupName $sourceresourcegroupname
# Remove-AzureRmResourceGroup -ResourceGroupName $targetresourcegroupname