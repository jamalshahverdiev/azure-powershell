Clear-Host
$subscrID = 'a261b2a5-86f5-4b9e-812f-1566a7ea696a'
$localPath = (Get-Item -Path ".\").FullName

$Host.UI.RawUI.WindowTitle = "PoSH Menu Template"
function loadMainMenu() {
    [bool]$loopMainMenu = $true
    while ($loopMainMenu) {
        #Clear-Host  # Clear the screen.
        Write-Host -BackgroundColor Black -ForegroundColor White  "`n`tExecute Volvo DCOM tasks`t`n"
        Write-Host -BackgroundColor Black -ForegroundColor White  "`t`tMain Menu`t`t`n"
        $runasAlias = [Environment]::UserName
        Write-Host -BackgroundColor Black -ForegroundColor White "Running as: $runasAlias`n"
        Write-Host "`t`t`t1 - Installation and configuration of Octopus"
        Write-Host "`t`t`t2 - Installation and configuration of TeamCity"
        Write-Host "`t`t`t3 - Installation and configuration of SonarQube"
        Write-Host "`t`t`t4 - Installation and configuration of all Environments."
        Write-Host "`t`t`t5 - Installation and configuration of all Environments from one ARM template."
        Write-Host "`t`t`tQ --- Quit And Exit`n"
        Write-Host -BackgroundColor DarkCyan -ForegroundColor Red "`NOTICE:`t"
        Write-Host -BackgroundColor DarkCyan -ForegroundColor Red  "`An extra warning.`t`n"
        $mainMenu = Read-Host "`t`tEnter Menu Option Number" 
        switch ($mainMenu) {
            1 {
                Login-AzureRmAccount -Subscription $subscrID
                Initialize-Octopus  
            } 
            2 {
                Login-AzureRmAccount -Subscription $subscrID
                Initialize-TeamCity 
            } 
            3 {
                Login-AzureRmAccount -Subscription $subscrID
                Initialize-SonarQube $subscrID
            } 
            4 {
                Initialize-AllInOne $subscrID
                $loopMainMenu = $false
            }
            5 {
                Login-AzureRmAccount -Subscription $subscrID
                Initialize-AllFromARM $subscrID
                $loopMainMenu = $false
            } 
            "q" {
                $loopMainMenu = $false
                Clear-Host
                Write-Host -BackgroundColor DarkCyan -ForegroundColor Yellow "`t`t`t`t`t"
                Write-Host -BackgroundColor DarkCyan -ForegroundColor Red "`tGoodbye!`t`t`t"
                Write-Host -BackgroundColor DarkCyan -ForegroundColor Yellow "`t`t`t`t`t"
                Start-Sleep -Seconds 3
                $Host.UI.RawUI.WindowTitle = "Windows PowerShell" # Set back to standard.
                Clear-Host
                Exit-PSSession
            }
            default {
                Write-Host -BackgroundColor Red -ForegroundColor White "You did not enter a valid menu selection. Please enter a valid selection."
                Start-Sleep -Seconds 2
            }
        }
    }
    return
}

function Get-Status ($softName) {
    if ( $? -eq 'True' )
    { Write-Host -BackgroundColor Black -ForegroundColor White "`n`t$softName installed and configured successful`t`n" }
    else 
    { 
        Write-Host -BackgroundColor Black -ForegroundColor White "`n`tThe installation of the $softName was unsuccessful`t`n"
        exit 127 
    }    
}

function Initialize-Octopus() {
    Write-Host -BackgroundColor Black -ForegroundColor White  "`n`tExecute Octopus Installation and Configuration`t`n"
    . "$localPath\Octopus-Installation-Automation\Deploy-AzureResourceGroup.ps1" -UploadArtifacts
    Get-Status 'Octopus'
}

function Initialize-TeamCity() {
    Write-Host -BackgroundColor Black -ForegroundColor White  "`n`tExecute TeamCity Installation and Configuration`t`n"
    . "$localPath\TeamCity-Installation-Automation\Deploy-AzureResourceGroup.ps1" -UploadArtifacts
    Get-Status 'TeamCity'
}

function Initialize-SonarQube($subscrID) {
    Write-Host -BackgroundColor Black -ForegroundColor White  "`n`tExecute Octopus Installation and Configuration`t`n"
    . "$localPath\SonarQube-Installation-Automation\deploy.ps1" -subscriptionId $subscrID 
    Get-Status 'SonarQube'
}

function Initialize-AllInOne($subscrID) {
    Login-AzureRmAccount -Subscription $subscrID
    Initialize-Octopus 
    Initialize-TeamCity 
    Initialize-SonarQube $subscrID
}

function Initialize-AllFromARM($subscrID) {
    Write-Host -BackgroundColor Black -ForegroundColor White  "`n`tExecute all from one Arm template Installation and Configuration`t`n"
    . "$localPath\OTS-one-ARM\Deploy-AzureResourceGroup.ps1" -UploadArtifacts
    Get-Status 'AllInOne'
}

# Start the Menu once loaded:
loadMainMenu

# Extras:
if ($clearHost) {Clear-Host}
if ($exitSession) {Exit-PSSession};