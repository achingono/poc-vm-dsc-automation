Configuration ServerConfiguration {

    param (
        [Parameter(Mandatory = $true)]
        [string] $siteName,
        [Parameter(Mandatory = $true)]
        [string] $applicationPool,
        [Parameter(Mandatory = $true)]
        [string] $packageUrl,
        [Parameter(Mandatory = $true)]
        [string] $packageName,
        [Parameter(Mandatory = $true)]
        [string] $decryptionKey,
        [Parameter(Mandatory = $true)]
        [string] $validationKey,
        [Parameter(Mandatory = $false)]
        [string] $downloadPath = "C:\Deploy\Packages"
    )

    #Install-Module -Name xWebAdministration -Force
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration

    Node localhost {

        # Install required Windows features
        WindowsFeature IIS {
            Ensure = "Present"
            Name   = "Web-Server"
        }

        WindowsFeature  NETFramework45 {
            Ensure = "Present"
            Name   = "NET-Framework-45-ASPNET"
        }

        WindowsFeature ASPNET45 {
            Ensure = "Present"
            Name   = "Web-Asp-Net45"
        }

        Script NgenUpdate {
            DependsOn  = "[WindowsFeature]IIS", "[WindowsFeature]NETFramework45", "[WindowsFeature]ASPNET45"
            GetScript  = { return @{ Result = "Installed" } }
            SetScript  = {
                &$Env:windir\Microsoft.NET\Framework64\v4.0.30319\ngen update; 
                &$Env:windir\Microsoft.NET\Framework\v4.0.30319\ngen update;
            }
            TestScript = {
                # Test if NgenUpdate has been run
                return $false
            }
        }

        WindowsFeature WebASP {
            DependsOn = "[Script]NgenUpdate"
            Ensure    = "Present"
            Name      = "Web-ASP"
        }

        WindowsFeature WebCGI {
            DependsOn = "[Script]NgenUpdate"
            Ensure    = "Present"
            Name      = "Web-CGI"
        }

        WindowsFeature WebISAPIExt {
            DependsOn = "[Script]NgenUpdate"
            Ensure    = "Present"
            Name      = "Web-ISAPI-Ext"
        }

        WindowsFeature WebISAPIFilter {
            DependsOn = "[Script]NgenUpdate"
            Ensure    = "Present"
            Name      = "Web-ISAPI-Filter"
        }

        WindowsFeature WebIncludes {
            DependsOn = "[Script]NgenUpdate"
            Ensure    = "Present"
            Name      = "Web-Includes"
        }

        WindowsFeature WebHTTPErrors {
            DependsOn = "[Script]NgenUpdate"
            Ensure    = "Present"
            Name      = "Web-HTTP-Errors"
        }

        WindowsFeature WebCommonHTTP {
            DependsOn = "[Script]NgenUpdate"
            Ensure    = "Present"
            Name      = "Web-Common-HTTP"
        }

        WindowsFeature WebPerformance {
            DependsOn = "[Script]NgenUpdate"
            Ensure    = "Present"
            Name      = "Web-Performance"
        }

        WindowsFeature WAS {
            DependsOn = "[Script]NgenUpdate"
            Ensure    = "Present"
            Name      = "WAS"
        }

        WindowsFeature WebMgmtConsole {
            DependsOn = "[Script]NgenUpdate"
            Ensure    = "Present"
            Name      = "Web-Mgmt-Console"
        }

        WindowsFeature WebMgmtService {
            DependsOn = "[Script]NgenUpdate"
            Ensure    = "Present"
            Name      = "Web-Mgmt-Service"
        }

        WindowsFeature WebScriptingTools {
            DependsOn = "[Script]NgenUpdate"
            Ensure    = "Present"
            Name      = "Web-Scripting-Tools"
        }

        WindowsFeature WebDefaultDoc {
            DependsOn = "[WindowsFeature]IIS"
            Ensure    = "Present"
            Name      = "Web-Default-Doc"
        }

        # Enable remote management for IIS
        Registry EnableRemoteManagement {
            DependsOn = "[WindowsFeature]WebMgmtService"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WebManagement\Server"
            ValueName = "EnableRemoteManagement"
            ValueType = "Dword"
            ValueData = "1"
            Force     = $true
            Ensure    = "Present"
        }

        Registry EnableLogging {
            DependsOn = "[WindowsFeature]WebMgmtService"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WebManagement\Server"
            ValueName = "EnableLogging"
            ValueType = "Dword"
            ValueData = "1"
            Force     = $true
            Ensure    = "Present"
        }

        Registry TracingEnabled {
            DependsOn = "[WindowsFeature]WebMgmtService"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WebManagement\Server"
            ValueName = "TracingEnabled"
            ValueType = "Dword"
            ValueData = "1"
            Force     = $true
            Ensure    = "Present"
        }

        # Set IIS Remote Management Service to start automatically and start it
        Service WMSVC {
            Name        = "WMSVC"
            StartupType = "Automatic"
            State       = "Running"
            DependsOn   = @("[Registry]EnableRemoteManagement", "[Registry]EnableLogging", "[Registry]TracingEnabled")
        }

        # Install C++ 2017 distributions
        Package VCRedist2017x64 {
            Ensure    = "Present"
            Path      = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
            Name      = "Microsoft Visual C++ 2022 X64 Additional Runtime - 14.38.33135"
            ProductId = "{19AFE054-CA83-45D5-A9DB-4108EF4BD391}"
            Arguments = "/install /quiet /norestart"
        }

        Package VCRedist2017x86 {
            Ensure    = "Present"
            Path      = "https://aka.ms/vs/17/release/vc_redist.x86.exe"
            Name      = "Microsoft Visual C++ 2022 X86 Additional Runtime - 14.38.33135"
            ProductId = "{9C19C103-7DB1-44D1-A039-2C076A633A38}"
            Arguments = "/install /quiet /norestart"
        }

        # Install ODBC Driver
        Package ODBCDriver {
            Ensure    = "Present"
            Path      = "https://download.microsoft.com/download/f/1/3/f13ce329-0835-44e7-b110-44decd29b0ad/en-US/19.3.1.0/x64/msoledbsql.msi"
            Name      = "Microsoft OLE DB Driver 19 for SQL Server"
            ProductId = "{06D41C8F-B812-4625-B035-2209B1AF94B1}"
            Arguments = "IACCEPTMSOLEDBSQLLICENSETERMS=YES /quiet /norestart"
        }

        # Install IIS Rewrite Module
        Package IISRewrite {
            Ensure    = "Present"
            Path      = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
            Name      = "IIS URL Rewrite Module 2"
            ProductId = "{9BCA2118-F753-4A1E-BCF3-5A820729965C}"
            Arguments = "/quiet /norestart"
            DependsOn = "[WindowsFeature]IIS"
        }

        # Install Web Deploy
        Package InstallWebDeploy {
            Ensure    = "Present"  
            Path      = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
            Name      = "Microsoft Web Deploy 3.6"
            ProductId = "{6773A61D-755B-4F74-95CC-97920E45E696}"
            Arguments = "ADDLOCAL=ALL /quiet /norestart"
            DependsOn = "[WindowsFeature]WebMgmtService"
        }

        # Unlock the IIS configuration
        Script UnlockASPConfig {
            GetScript  = { return @{ Result = "Unlocked" } }
            SetScript  = { & c:\windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/asp }
            TestScript = { return $false }
            DependsOn  = "[WindowsFeature]IIS"
        }

        Script UnlockHandlersConfig {
            GetScript  = { return @{ Result = "Unlocked" } }
            SetScript  = { & c:\windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/handlers }
            TestScript = { return $false }
            DependsOn  = "[WindowsFeature]IIS"
        }

        Script UnlockModulesConfig {
            GetScript  = { return @{ Result = "Unlocked" } }
            SetScript  = { & c:\windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/modules }
            TestScript = { return $false }
            DependsOn  = "[WindowsFeature]IIS"
        }

        # Enable Fusion Logs
        Registry EnableFusionForceLogs {
            DependsOn = "[WindowsFeature]IIS"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Fusion"
            ValueName = "ForceLog"
            ValueType = "Dword"
            ValueData = "1"
            Force     = $true
            Ensure    = "Present"
        }

        Registry EnableFusionLogFailures {
            DependsOn = "[WindowsFeature]IIS"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Fusion"
            ValueName = "LogFailures"
            ValueType = "Dword"
            ValueData = "1"
            Force     = $true
            Ensure    = "Present"
        }

        Registry EnableFusionLogResourceBinds {
            DependsOn = "[WindowsFeature]IIS"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Fusion"
            ValueName = "LogResourceBinds"
            ValueType = "Dword"
            ValueData = "1"
            Force     = $true
            Ensure    = "Present"
        }

        Registry SetFusionLogPath {
            DependsOn = "[WindowsFeature]IIS"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Fusion"
            ValueName = "LogPath"
            ValueType = "String"
            ValueData = "C:\inetpub\logs\fusionlogs"
            Force     = $true
            Ensure    = "Present"
        }

        # Update Default IISSite
        xWebsite DefaultSite {
            DependsOn = "[WindowsFeature]IIS"
            Ensure       = "Present"
            Name         = "Default Web Site"
            State        = "Started"
            PhysicalPath = "C:\inetpub\wwwroot"
            BindingInfo  = @(
                MSFT_xWebBindingInformation {
                    Protocol  = "http"
                    Port      = "8080"
                    IPAddress = "*"
                }
            )
        }

        # Create Application Pool
        xWebAppPool $applicationPool {
            DependsOn = "[WindowsFeature]IIS"
            Ensure                = "Present"
            Name                  = $applicationPool
            State                 = "Started"
            ManagedRuntimeVersion = "v4.0"
            ManagedPipelineMode   = "Integrated"
            Enable32BitAppOnWin64 = $false
            AutoStart             = $true
        }

        File WebsitePath {
            Ensure = "Present"
            Type   = "Directory"
            DestinationPath = "C:\inetpub\$siteName"
        }

        # Create IISSite
        xWebsite $siteName {
            DependsOn = "[File]WebsitePath", '[WindowsFeature]IIS', "[xWebAppPool]$applicationPool"
            Ensure          = "Present"
            Name            = $siteName
            State           = "Started"
            PhysicalPath    = "C:\inetpub\$siteName"
            ApplicationPool = $applicationPool
            BindingInfo     = @(
                MSFT_xWebBindingInformation {
                    Protocol  = "http"
                    Port      = "80"
                    IPAddress = "*"
                }
            )
        }

        File DownloadPath {
            Ensure = "Present"
            Type   = "Directory"
            DestinationPath = $downloadPath
        }

        # Download the package
        Script DownloadWebPackage {
            DependsOn = "[File]DownloadPath"
            GetScript  = {
                @{
                    Result = ""
                }
            }
            TestScript = {
                $false
            }
            SetScript  = {
                Invoke-WebRequest -Uri $using:packageUrl -OutFile "$using:downloadPath\$using:packageName" -Verbose
            }
        }

        # Deploy the package
        Script DeployWebPackage {
            DependsOn = "[Script]DownloadWebPackage", "[Package]InstallWebDeploy"
            GetScript  = {
                @{
                    Result = ""
                }
            }
            TestScript = {
                $false
            }
            SetScript  = {
                $packagePath = Join-Path -Path $using:downloadPath -ChildPath $using:packageName;
                $msDeployPath = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy" | Select -Last 1).GetValue("InstallPath");
                $arguments = "-verb:sync -source:package=$packagePath -dest:iisApp='$using:siteName' -setParam:name='Decryption Key',value='$using:decryptionKey' -setParam:name='Validation Key',value='$using:validationKey' -verbose -debug";

                # Deploy the package to the Site
                Start-Process "$msDeployPath\msdeploy.exe" $arguments -Verb runas;            
            }
        }    
    }            
}
