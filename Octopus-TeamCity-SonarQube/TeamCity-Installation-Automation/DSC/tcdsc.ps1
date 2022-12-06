Configuration Main
{

Param ( [string] $nodeName, 
        [string] $mainScriptUrl,
        [string] $commonScriptUrl,
		    [string] $iisScriptUrl,
		    [string] $teamCityScriptUrl,
        [string] $certFileUrl,
        [string] $webConfigUrl,
        [string] $serverXmlUrl,
        [string] $buildPropertiesUrl,
        [string] $wrapperConfUrl,
        [string] $logonAsServiceUrl,
        [string] $subinAclMsiUrl
)

Import-DscResource -ModuleName xWebAdministration
Import-DscResource -ModuleName xPSDesiredStateConfiguration
Import-DscResource -ModuleName PSDesiredStateConfiguration

Node $nodeName
  {
    File CreateScriptsFolder {
          Type = 'Directory'
          DestinationPath = 'C:\Scripts\Includes'
          Ensure = "Present"
    }
    File CreateTempFolder {
      Type = 'Directory'
      DestinationPath = 'C:\Scripts\Temps'
      Ensure = "Present"
    }
    xRemoteFile loadMainScript {
          Uri = "$mainScriptUrl"
          DestinationPath = "C:\Scripts\Install.ps1"
          MatchSource = $true
    }
    xRemoteFile loadCommonScript {
        Uri = "$commonScriptUrl"
        DestinationPath = "C:\Scripts\Includes\Common.ps1"
        MatchSource = $true
    }
    xRemoteFile loadIISScript {
        Uri = "$iisScriptUrl"
        DestinationPath = "C:\Scripts\Includes\IIS.ps1"
        MatchSource = $true
    }
    xRemoteFile loadTeamCityScript {
        Uri = "$teamCityScriptUrl"
        DestinationPath = "C:\Scripts\Includes\TeamCity.ps1"
        MatchSource = $true
    }
    xRemoteFile loadCertFile {
        Uri = "$certFileUrl"
        DestinationPath = "C:\Scripts\build-digitalcommerce-volvocars-com.pfx"
        MatchSource = $true
    }
    xRemoteFile loadWebConfigFile {
      Uri = "$webConfigUrl"
      DestinationPath = "C:\Scripts\Temps\web.config"
      MatchSource = $true
    }
    xRemoteFile loadServerXmlFile {
      Uri = "$serverXmlUrl"
      DestinationPath = "C:\Scripts\Temps\partOfServer.xml"
      MatchSource = $true
    }
    xRemoteFile loadBuildTemplate {
      Uri = "$buildPropertiesUrl"
      DestinationPath = "C:\Scripts\Temps\buildAgent.properties.template"
      MatchSource = $true
    }
    xRemoteFile loadWrapperTemplate {
      Uri = "$wrapperConfUrl"
      DestinationPath = "C:\Scripts\Temps\wrapper.conf.template"
      MatchSource = $true
    }
    xRemoteFile loadLogonScript {
      Uri = "$logonAsServiceUrl"
      DestinationPath = "C:\Scripts\Includes\LogonAsService.ps1"
      MatchSource = $true
    }
    xRemoteFile loadSubinAclMsi {
      Uri = "$subinAclMsiUrl"
      DestinationPath = "C:\Scripts\Temps\subinacl.msi"
      MatchSource = $true
    }
  }
}