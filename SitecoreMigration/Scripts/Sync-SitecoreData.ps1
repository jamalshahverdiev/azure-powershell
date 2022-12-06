param($randomPass, $sqlAdminLogin, $sqlAdminpass, $oldsqlsrvName, $newsqlsrvName, $dbName)

if (!(Test-Path '.\Unicorn.psm1')) {
    $microChap = 'https://raw.githubusercontent.com/kamsar/Unicorn/master/doc/PowerShell Remote Scripting/MicroCHAP.dll'
    $unicornModule = 'https://raw.githubusercontent.com/kamsar/Unicorn/master/doc/PowerShell Remote Scripting/Unicorn.psm1'
    Invoke-WebRequest -Uri $microChap -OutFile ([System.IO.Path]::GetFileName($microChap))
    Invoke-WebRequest -Uri $unicornModule -OutFile ([System.IO.Path]::GetFileName($unicornModule))
}
     
Import-Module '.\Unicorn.psm1'
Sync-Unicorn -ControlPanelUrl 'http://localhost:10081/unicorn.aspx' -SharedSecret $randomPass -Verb 'Reserialize'
Sync-Unicorn -ControlPanelUrl 'http://localhost:10080/unicorn.aspx' -SharedSecret $randomPass -Verb 'Sync'


$Query = "SELECT u.[UserName], m.[Password], m.[PasswordSalt] FROM [dbo].[aspnet_Membership] m JOIN [dbo].[aspnet_Users] u on u.UserId = m.UserId"
$userEntries = Invoke-SqlCmd -Username "$sqlAdminLogin" -Password "$sqlAdminpass" -ServerInstance $oldsqlsrvName -Database $dbName -Query $Query 
$userEntries | ForEach-Object {
    $Query = 
    @"
DECLARE @ProcessedUserId uniqueidentifier
SELECT @ProcessedUserId = UserId FROM dbo.aspnet_Users WHERE UserName = '$($_.UserName)'
UPDATE [aspnet_Membership] SET [Password] = '$($_.Password)',
[PasswordSalt] = '$($_.PasswordSalt)'
WHERE UserId = @ProcessedUserId
"@
    Invoke-SqlCmd -Username "$sqlAdminLogin" -Password "$sqlAdminpass" -ServerInstance $newsqlsrvName -Database $dbName -Query $Query
}