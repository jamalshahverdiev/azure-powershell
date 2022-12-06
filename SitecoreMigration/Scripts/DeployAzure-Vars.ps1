$paramsjson = (Get-Content "WindowsVirtualMachine.parameters.json" -Raw) | ConvertFrom-Json
$sqlAdminLogin = $paramsjson.parameters.sqlAdministratorLogin.value
$sqlAdminpass = $paramsjson.parameters.sqlAdministratorLoginPassword.value
$pwd = ConvertTo-SecureString $sqlAdminpass -AsPlainText -Force
$secpword = ConvertTo-SecureString -String $paramsjson.parameters.adminPassword.value -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($paramsjson.parameters.adminUsername.value, $secpword)
Invoke-Expression (Get-Content .\Scripts\Setup-Role.ps1 | findstr ^'$dbNameArray')
Invoke-Expression (Get-Content .\Scripts\Setup-Role.ps1 | findstr '^$randomPass')