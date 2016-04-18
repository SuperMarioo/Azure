
Configuration WebServer
{


Import-DscResource -ModuleName PSDesiredStateConfiguration
Import-DscResource -ModuleName xTimeZone

Node WebServer

  {

$WindowsFeatures = "Web-Server","Web-Mgmt-Console","Web-Mgmt-Service", `
"Web-Asp-Net45","Web-Http-Redirect","Web-Custom-Logging","Web-Log-Libraries",`
"Web-Request-Monitor","Web-Http-Tracing","Web-Basic-Auth","Web-Windows-Auth", `
"Web-AppInit","Telnet-Client"

    ## Installing Windows Features

    foreach ($WindowsFeature in $WindowsFeatures) {

    WindowsFeature  $WindowsFeature.tostring().replace("-","") {

    Name = $WindowsFeature
    Ensure = "present"


    }

    }

    ## Setting TimeZone

    xTimeZone  Set-UKTime {

    TimeZone = "GMT Standard Time"
    IsSingleInstance = "Yes"


    }

    ## BG Info Setup

    Script DownloadBGINFO
    {
        TestScript = {
            Test-Path "C:\WindowsAzure\BGInfo.zip"
        }
        SetScript ={
            $source = "https://github.com/SuperMarioo/Azure/blob/master/Files/BGInfo.zip?raw=true"
            $dest = "C:\WindowsAzure\BGInfo.zip"
            Invoke-WebRequest $source -OutFile $dest
        }
        GetScript = {@{Result = "BGInfo"}}

    }

    Archive  BGINFO {

        Ensure = "Present"
        Path = "C:\WindowsAzure\BGInfo.zip"
        Destination = "C:\Program Files\"
        DependsOn = "[Script]DownloadBGINFO"

    }

    File BGinfoShourtcut_COpy  {

    Ensure = "present"
    Type = "file"
    DestinationPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
    SourcePath = "C:\Program Files\BgInfo\Bginfo_Shortcut.lnk"
    Force = $true
    DependsOn = '[Archive]BGINFO'


    }

    ## Disabling ESC for IE 

    Registry Disable_ESCAdmin{

    Key = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    ValueName = "IsInstalled"
    ValueData = 0
    ValueType = "Dword"

    }  
    
    Registry Disable_ESCUser{

    Key = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    ValueName = "IsInstalled"
    ValueData = 0
    ValueType = "Dword"

    }   

    ## Disabling UAC


    Registry Disable_UAC{

    Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    ValueName = "EnableLUA"
    ValueData = 1
    ValueType = "Dword"
    

    }   

   ## Installing DownloadWebDeploy

    Script DownloadWebDeploy
    {
        TestScript = {
            Test-Path "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
        }
        SetScript ={
            $source = "http://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
            $dest = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
            Invoke-WebRequest $source -OutFile $dest
        }
        GetScript = {@{Result = "DownloadWebDeploy"}}
        DependsOn = "[WindowsFeature]WebServer"
    }
    Package InstallWebDeploy
    {
        Ensure = "Present"  
        Path  = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
        Name = "Microsoft Web Deploy 3.6"
        ProductId = "{ED4CC1E5-043E-4157-8452-B5E533FE2BA1}"
        Arguments = "ADDLOCAL=ALL"
        DependsOn = "[Script]DownloadWebDeploy"
    }
    Service StartWebDeploy
    {                    
        Name = "WMSVC"
        StartupType = "Automatic"
        State = "Running"
        DependsOn = "[Package]InstallWebDeploy"


    } 

    ## Generate File for Load Balancer check 

    Script GenerateFile
    {
        TestScript = {
            Test-Path "c:\WindowsAzure\servername.txt"
        }
        SetScript ={
            
            $env:COMPUTERNAME | Out-File "c:\WindowsAzure\servername.txt"

        }
        GetScript = {@{Result = "DownloadWebDeploy"}}

    }
    
    file GenerateFileCopy {

    Ensure = "present"
    Type = "file"
    DestinationPath = "C:\inetpub\wwwroot"
    SourcePath = "c:\WindowsAzure\servername.txt"
    DependsOn = "[Script]GenerateFile","[WindowsFeature]WebServer"

    }


  }

}

WebServer -OutputPath C:\DSC -Verbose 

## Upload Config to Azure DSC Server 

Login-AzureRmAccount

Import-AzureRmAutomationDscNodeConfiguration -path "C:\dsc\WebServer.mof" -ConfigurationName "Praemium" -ResourceGroupName "Powershell" -AutomationAccountName "Mariusz" -Force
