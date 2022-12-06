Import-AzureRmContext -path (Get-ChildItem .\AvanadeCredentials.json).FullName | Out-Null

$resourceGroupNames = ((Get-Content .\Deploy-AzureResourceGroup.ps1 | Where-Object { $_ -Match "Octo" -and $_ -NotMatch "Installer"} | ForEach-Object { $_.Split('=')[1]; }) -replace "`'|`,").trim()

foreach ($rgname in $resourceGroupNames) {
    Write-Host "Started deletion of the resource group:" $rgname
    Remove-AzureRmResourceGroup -Name $rgname -Force
}
