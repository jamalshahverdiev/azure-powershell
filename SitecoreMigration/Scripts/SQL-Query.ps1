Param(
    [string] $fqdn,
    [string] $oldsqlsrvName,
    [string] $newsqlsrvName,
    [string] $databaseName
)

$SessionOption = New-PSSessionOption -SkipCACheck
$s = New-PSSession -ComputerName $fqdn -Credential $Credential -Port 5986 -UseSSL -SessionOption $SessionOption
Invoke-Command -session $s -FilePath .\Scripts\Sync-SitecoreData.ps1 -ArgumentList $randomPass, $sqlAdminLogin, $sqlAdminpass, $oldsqlsrvName, $newsqlsrvName, $databaseName
Remove-PSSession $s