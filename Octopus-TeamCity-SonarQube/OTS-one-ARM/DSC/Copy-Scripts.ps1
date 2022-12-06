Configuration Main
{

Param ( [string] $nodeName, 
        [string] $scriptUrl,
        [string] $certScriptUrl,
        [string] $certUrl
)

Import-DscResource -ModuleName xWebAdministration
Import-DscResource -ModuleName xPSDesiredStateConfiguration
Import-DscResource -ModuleName PSDesiredStateConfiguration

Node $nodeName
  {
	  File CreateScriptsFolder {
        Type = 'Directory'
        DestinationPath = 'C:\Scripts'
        Ensure = "Present"
    }
    xRemoteFile downloadAPIScriptFile {
        Uri = "$scriptUrl"
        DestinationPath = "C:\Scripts\octopus-api-token-create.ps1"
        MatchSource = $true
    }
    xRemoteFile loadCertScriptFile {
      Uri = "$certScriptUrl"
      DestinationPath = "C:\Scripts\certconfigureoctohttps.ps1"
      MatchSource = $true
    }
    xRemoteFile loadCertFile {
      Uri = "$certUrl"
      DestinationPath = "C:\Scripts\deploy-digitalcommerce-volvocars-com.pfx"
      MatchSource = $true
    }
  }
}