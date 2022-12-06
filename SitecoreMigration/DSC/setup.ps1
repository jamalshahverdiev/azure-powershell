Configuration Main
{

Param ( [string] $nodeName, 
	[string] $oldSitecore, 
  [string] $newSitecore,
  [string] $unicornPackage,
  [string] $licenseFile,
  [string] $unicornConfig,
  [string] $unicornLangPack
  )

Import-DscResource -ModuleName xWebAdministration
Import-DscResource -ModuleName xPSDesiredStateConfiguration
Import-DscResource -ModuleName PSDesiredStateConfiguration

Node $nodeName
  {
    File stnewWebAppFolder {
        Type = 'Directory'
        DestinationPath = 'C:\inetpub\sitecorenew\Website'
        Ensure = "Present"
    }
    File stoldWebAppFolder {
        Type = 'Directory'
        DestinationPath = 'C:\inetpub\sitecoreold\Website'
        Ensure = "Present"
    }
    xRemoteFile stcoreoldFileDownload {
        Uri = "$oldSitecore"
        DestinationPath = "C:\Software\sitecoreold.zip"
        MatchSource = $true
    }
    xRemoteFile stcorenewFileDownload {
        Uri = "$newSitecore"
        DestinationPath = "C:\Software\sitecorenew.zip"
        MatchSource = $true
    }
    xRemoteFile unicornDownload {
      Uri = "$unicornPackage"
      DestinationPath = "C:\Software\unicorn.zip"
      MatchSource = $true
    }
    xRemoteFile licenseDownload {
      Uri = "$licenseFile"
      DestinationPath = "C:\Software\license.xml"
      MatchSource = $true
    }
    xRemoteFile unicornConfigDownload {
      Uri = "$unicornConfig"
      DestinationPath = "C:\Software\Unicorn.config"
    }
    xRemoteFile ucornLangPackDownload {
      Uri = "$unicornLangPack"
      DestinationPath = "C:\Software\Install-Cultures.zip"
    }
    WindowsFeature WebServerRole
    {
      Name = "Web-Server"
      Ensure = "Present"
    }
    xWebsite DefaultSite
    {
        Ensure          = "Present"
        Name            = "Default Web Site"
        State           = "Stopped"
        PhysicalPath    = "C:\inetpub\wwwroot"
        DependsOn       = "[WindowsFeature]WebServerRole"
    }
    WindowsFeature WebManagementConsole
    {
      Name = "Web-Mgmt-Console"
      Ensure = "Present"
    }
    WindowsFeature ASPNet45
    {
      Name = "Web-Asp-Net45"
      Ensure = "Present"
    }
    xWebAppPool stnewWebAppPool 
    { 
        Name            = "stnewwebpool"
        Ensure          = "Present"
        State           = "Started"
    } 
    xWebsite stnewWebSite
    {
        Ensure          = "Present"
        Name            = "Sitecore new Web Site"
        State           = "Started"
        PhysicalPath    = "C:\inetpub\sitecorenew\Website"
        ApplicationPool = "stnewwebpool"
        BindingInfo = MSFT_xWebBindingInformation
        {
                Protocol = "http"
                Port = 10080
        }
        DependsOn       = "[xWebAppPool]stnewWebAppPool"
    }
    xWebAppPool stoldWebAppPool 
    { 
        Name            = "stoldwebpool"
        Ensure          = "Present"
        State           = "Started"
    } 
    xWebsite stoldWebSite
    {
        Ensure          = "Present"
        Name            = "Sitecore old Web Site"
        State           = "Started"
        PhysicalPath    = "C:\inetpub\sitecoreold\Website"
        ApplicationPool = "stoldwebpool"
        BindingInfo = MSFT_xWebBindingInformation
        {
                Protocol = "http"
                Port = 10081
        }
        DependsOn       = "[xWebAppPool]stoldWebAppPool"
    }
  }
}
