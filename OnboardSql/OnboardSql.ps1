# 
## File: OnboardSql.ps1
## Purpose: Script to automate the onboarding of the Sql Server.
#
# Version 1.0 Initial Release
#
<#   
.SYNOPSIS   
   Test to ensure all the prerequisites are met when onboarding a Sql Server. This script is to be run on the source SQL server. It can perform a discovery of the both the SQL Windows server and VDP appliance environment. After the discovery process, it will report on all the SQL Server prerequisites for VDP appliance.
.DESCRIPTION 
   This is a powershell script that helps you automate the onboarding of a Windows server. It can register the server with a VDP appliance.
.PARAMETER srcsql
    To list the components on the source Windows server required by the VDP appliance onboarding, use -srcsql switch
.PARAMETER tgtvdp
    To check the requirements required by the target VDP appliance from the VDP appliance, use -tgtvdp switch
.EXAMPLE
    PS C:\users\johndoe\Desktop> .\OnboardSQL.ps1

    To get help on how to use the script

    PS > .\OnboardSql.ps1 -srcsql -tgtvdp -vdpip 10.10.10.1-vdpuser cliuser -vdppasword TopSecret 

    To check the source SQL Server and target VDP appliance (IP address: 10.10.10.1) using the CLI user (cliuser - TopSecret). 

    PS > .\OnboardSql.ps1 -srcsql -tgtvdp -vdpip 10.10.10.1-vdpuser cliuser -vdppasword TopSecret -ToExec 

    To check the source SQL Server and target VDP appliance (IP address: 10.10.10.1) using the CLI user (cliuser - TopSecret). Also register the source SQL server with VDP appliance.

.NOTES   
    Name: OnboardSql.ps1
    Author: Michael Chew
    DateCreated: 3-April-2020
    LastUpdated: 7-April-2020
.LINK
    https://github.com/Actifio/powershell/blob/master/OnboardSql   
#>

[CmdletBinding()]
Param
( 
  [switch]$srcsql = $false,         
  [switch]$tgtvdp = $false,      
  [switch]$ToExec = $false,  
  [string]$vdpip = "",           
  [string]$vdpuser = "",        
  [string]$vdppassword = ""   
)  ### Param

$ScriptVersion = "1.0"

function Get-SrcWin-Info ()
{
  Write-Host "I will be gathering information on Windows Host. "

  ## Find the Windows version on the source Windows Server
  $WinVer = Get-WmiObject -Class Win32_OperatingSystem | ForEach-Object -MemberName Caption
  $thisObject | Add-Member -MemberType NoteProperty -Name 'Windows Version' -Value $("$WinVer")

  ## Find the source Windows Server computername
  $thisObject | Add-Member -MemberType NoteProperty -Name ComputerName -Value $("$env:COMPUTERNAME")

  ## Find the source Windows Server FQDN
  $CurrentFQDN = [System.Net.DNS]::GetHostByName($Null).HostName
  $thisObject | Add-Member -MemberType NoteProperty -Name FQDN -Value $("$CurrentFQDN")

    ## Find the source Windows Server IP address
    $CurrentIP = ( Get-NetIPConfiguration |
    Where-Object {
        $null -ne $_.IPv4DefaultGateway -And
        $_.NetAdapter.Status -ne "Disconnected"
    } ).IPv4Address.IPAddress
  $thisObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value $("$CurrentIP")
}

##################################
# Function: Get-SrcSql-Info
#
# Download the ActPowerCLI from GitHub
# 
##################################
function Get-SrcSql-Info ()
{
  Write-Host "I will be gathering information on Sql Server Host. "

  ## Get the status of iSCSI service : Running, Stopped
  $iSCSIStatus = $(get-service msiscsi).status
  $thisObject | Add-Member -MemberType NoteProperty -Name iSCSIStatus -Value $("$iSCSIStatus")

  ## Get the status of firewall for iSCSI service : "Running", "Stopped"
  $iSCSIfirewall = Get-NetFirewallRule -DisplayGroup "iscsi Service"

  Get-NetFirewallProfile | select Name, Enabled | ForEach-Object { 
    $Label = $_.Name + "Firewall"
    $thisObject | Add-Member -MemberType NoteProperty -Name $Label  -Value ($_.Enabled).ToString()
  }

  ## $iSCSIfwIn.Enabled , $iscsifwOut.Enabled : "True"
  $iSCSIfwIn = $iSCSIfirewall | Where-Object {$_.Name -eq "MsiScsi-In-TCP"}
  $iscsifwOut = $iSCSIfirewall | Where-Object {$_.Name -eq "MsiScsi-Out-TCP"}

  $thisObject | Add-Member -MemberType NoteProperty -Name iSCSIfwInStatus -Value ($($iSCSIfwIn.Enabled)).ToString()
  $thisObject | Add-Member -MemberType NoteProperty -Name iSCSIfwOutStatus -Value ($($iSCSIfwOut.Enabled)).ToString()

  ## Start-Service msiscsi
  ## Set-Service msiscsi -startuptype "automatic"
  ## Set-NetFirewallRule -Name MsiScsi-In-TCP -Enabled True
  ## Set-NetFirewallRule -Name MsiScsi-Out-TCP -Enabled True

  if (! (Test-Path 'HKLM:\SOFTWARE\Actifio Inc')) {
    Write-Host "Actifio Software is not installed on this host !!"
    $ActVersion = $Null
  } else {
    $ActVersion = (Get-ItemProperty 'HKLM:\SOFTWARE\Actifio Inc\UDSAgent').Version
  }
  $thisObject | Add-Member -MemberType NoteProperty -Name ActVersion -Value $ActVersion  

  if (! (Test-Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server')) {
    $SQLInstalled = $False
    $SQLInstances = $Null
  } else {
    $SQLInstalled = $True
    $SQLInstances = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
    foreach ($sql in $SQLInstances) {
      [PSCustomObject]@{
        InstanceName = $sql
      }
    }
  }
  $thisObject | Add-Member -MemberType NoteProperty -Name SqlInstances -Value $SQLInstances  
  $thisObject | Add-Member -MemberType NoteProperty -Name SqlInstalled -Value $SQLInstalled

  $Pingable = Test-Connection $VdpIP -Count 1 -Quiet
  $thisObject | Add-Member -MemberType NoteProperty -Name Pingable -Value $Pingable  

  $VssWriters = @(vssadmin list writers | Select-String -Context 0,4 '^writer name:' | 
  Select @{Label="Writer"; Expression={$_.Line.Trim("'").SubString(14)}}, 
     ## @{Label="WriterID"; Expression={$_.Context.PostContext[0].Trim().SubString(11)}},
     ## @{Label="InstanceID"; Expression={$_.Context.PostContext[1].Trim().SubString(20)}},
     @{Label="State"; Expression={$_.Context.PostContext[2].Trim().SubString(11)}},
     @{Label="LastError"; Expression={$_.Context.PostContext[3].Trim().SubString(12)}})

  $thisObject | Add-Member -MemberType NoteProperty -Name VssWriters -Value $VssWriters     

  ## $thisObject | ogv

}       ## end if

##################################
# Function: Get-TgtVdp-Info
#
# Download the ActPowerCLI from GitHub
# 
##################################
function Get-TgtVdp-Info (
  [string]$VdpIp,             
  [string]$VdpUser,            
  [string]$VdpPassword,
  [bool]$WillExec
)
{
  Write-Host "I will be gathering information on Vdp Appliance. "
  
  if  (! ( Test-Connection $VdpIp -Count 2 -Quiet )) {
    Write-Host "Unable to ping / reach $VdpIp .. "
    exit 1
  }

  ## Ensure that the ActPowerCLI module is imported
  #
  $moduleins = get-module -listavailable -name ActPowerCLI
  if ($null -eq $moduleins) {
    Import-Module ActPowerCLI
  }

  $rc = connect-act -acthost $VdpIp -actuser $VdpUser -password $VdpPassword -ignorecerts

  if (! $env:ACTSESSIONID ) {
    Write-Host "Unable to connect to Vdp appliance $VdpIp .. "
    exit 1
  }
  
  write-Host "`n--------- S T A T U S      R E P O R T      P A R T 2 ----------------------------------`n"  
  write-host "`nTesting the connection from Vdp appliance to SQL Server $(($thisObject).IPAddress) on port 5106 (connector port)"
  write-host "> udstask testconnection -type tcptest -targetip $(($thisObject).IPAddress) -targetport 5106"
  $rc =udstask testconnection -type tcptest -targetip $thisObject.IPAddress -targetport 5106

  if ( $(($rc).result).Contains("succeeded!") ) {
    write-host "Passed: Vdp is able to communicate with the SQL Server $(($thisObject).IPAddress) on port 5106"
  } else {
    write-host "---> Failed: Vdp unable to communicate with the SQL Server $(($thisObject).IPAddress) on port 5106"
  }

  write-host "`nTesting the connection from Vdp appliance to SQL Server $(($thisObject).IPAddress) on port 443"
  write-host "> udstask testconnection -type tcptest -targetip $(($thisObject).IPAddress) -targetport 443"
  $rc = udstask testconnection -type tcptest -targetip $thisObject.IPAddress -targetport 443
  if ( $(($rc).result).Contains("succeeded!") ) {
    write-host "Passed: Vdp is able to communicate with the SQL Server $(($thisObject).IPAddress) on port 443"
  } else {
    write-host "---> Failed: Vdp unable to communicate with the SQL Server $(($thisObject).IPAddress) on port 443"
  }


  write-host "`n> udsinfo lsconfiguredinterface"
  write-host "The network interface on the Vdp appliance = $((udsinfo lsconfiguredinterface | select IPAddress).ipaddress) `n"
  
  $HostId = $(udsinfo lshost | Where-Object { $_.hostname -eq $(($thisObject).ComputerName) -And $_.hosttype -eq 'generic' } | Select-Object Id).Id

  if ($Null -eq $HostId) {

    write-host "`nRegistering the $(($thisObject).ComputerName) with Actifio Vdp appliance $VdpIp `n"
    $cmd = "udstask mkhost -hostname " + $(($thisObject).ComputerName) + " -ipaddress " + $(($thisObject).IPAddress) + " -type generic -appliance " + $VdpIp
    write-host "> $cmd"
    if ($true -eq $WillExec) {
      Invoke-Expression $cmd
    } 

    $HostId = $(udsinfo lshost | Where-Object { $_.hostname -eq $(($thisObject).ComputerName) } | Select-Object Id).Id
    write-host "`nUpdating the description for the $(($thisObject).ComputerName) entry in Actifio Vdp appliance $VdpIp `n"
    $cmd = "udstask chhost " + $hostid + " -description " + [char]34 + "Added by OnboardSql script" + [char]34
    write-host "> $cmd"
    if ($true -eq $WillExec) {
      Invoke-Expression $cmd
    } 

  } else {
    write-host "$(($thisObject).ComputerName) is already defined earlier in the Vdp appliance . No registration required! "
  }

  write-host "`nPerforming an application discovery on $(($thisObject).ComputerName) and updating the information in Vdp appliance $VdpIp `n"
  $cmd = "udstask appdiscovery -host " + $hostid
  write-host "> $cmd"
  if ($true -eq $WillExec) {
    Invoke-Expression $cmd
  } 

  write-host "`nPerforming an iSCSI test on $(($thisObject).ComputerName) from Vdp appliance $VdpIp (optional) : `n"
  $cmd = "udstask iscsitest -host " + $HostId 
  write-host "> $cmd"
  if ($true -eq $WillExec) {
    Invoke-Expression $cmd
  } 

  write-host "`nListing all applications discovered on $(($thisObject).ComputerName) stored in Vdp appliance $VdpIp : `n"
  $cmd = "udsinfo lsapplication | where { `$`_.HostId -eq $HostId } | Select-Object AppName, AppType "
  write-host "> $cmd"
  if ($true -eq $WillExec) {
    Invoke-Expression $cmd
  } 

  write-Host "`n---------------------------------------------------------------------------`n"

  Disconnect-Act
}       ## end if

##################################
# Function: Show-Usage
#
##################################
function Show-Usage ()
{
    write-host "Usage: .\OnboardSql.ps1 [ -srcsql ] [ -tgtvdp ] [ -ToExec ] [ -vdpip <Vdp IP appliance> [ -vdpuser <Vdp CLI user> ] [ -vdppassword <Vdp password> ] `n"
    write-host " get-help .\OnboardSql.ps1 -examples"
    write-host " get-help .\OnboardSql.ps1 -detailed"
    write-host " get-help .\OnboardSql.ps1 -full"    
}     ### end of function

function Show-WinObject-Info ()
{
  write-Host "`n--------- S T A T U S      R E P O R T      P A R T 1 ----------------------------------`n"  
  write-Host "            Computer Name: $(($thisObject).ComputerName) "
  write-Host "               IP Address: $(($thisObject).IPAddress) "
  write-Host "                     FQDN: $(($thisObject).FQDN) "  
  write-Host "                       OS: $(($thisObject).'Windows Version')`n"
  write-Host "`n---------------------------------------------------------------------------`n"
}

##################################
# Function: Show-SqlObject-Info
#
##################################
function Show-SqlObject-Info ()
{
  write-Host "          Domain Firewall: $(($thisObject).DomainFirewall) "
  write-Host "         Private Firewall: $(($thisObject).PrivateFirewall) "
  write-Host "          Public Firewall: $(($thisObject).PublicFirewall) "  
  write-Host "   iSCSI FireWall Inbound: $(($thisObject).iSCSIfwInStatus) "
  write-Host "  iSCSI FireWall Outbound: $(($thisObject).iSCSIfwOutStatus)`n"  

  if ( Test-Connection $VdpIp -Count 2 -Quiet ) {
    write-Host "Actifio Vdp Ip Pingable  : True "
  } else {
    write-Host "Actifio Vdp Ip Pingable  : False "
  }

  if ($False -eq $(($thisObject).SqlInstalled)) {
    write-Host "            SQL Server SW: Not Installed " 
  } else {
    write-Host "            SQL Server SW: Installed "
  }
  if ($null -eq  $(($thisObject).SqlInstances)) {
    write-Host "             SQL Instance: No Instances Created "
  } else {
    $(($thisObject).SqlInstances) | ForEach-Object { 
    write-Host "             SQL Instance: $_.InstanceName "  
      }
  }
  if ($null -eq  $(($thisObject).VssWriters)) {
    write-Host "              VSS Writers: Not Installed "
  } else {
    $(($thisObject).VssWriters) | ForEach-Object { 
    write-Host "     VSS Writer [ State ]: $($_.Writer) [ $($_.State) ] ( $($_.LastError) )"  
      }
  }
  write-Host "`n---------------------------------------------------------------------------`n"

}     ### end of function

##############################
#
#  M A I N    B O D Y
#
##############################

if ($false -eq $srcsql.IsPresent -And $false -eq $tgtvdp.IsPresent) {
  Show-Usage
  exit
}

## Create an object based on the PSObject class
$thisObject = New-Object -TypeName psobject 

Get-SrcWin-Info

if ($null -eq $VdpIp -Or "" -eq $VdpIp) {
  $VdpIp="172.27.24.96"
  $VdpPassword="12!pass345"
}

if ($true -eq $srcsql.IsPresent) {
  Get-SrcSql-Info
}

Show-WinObject-Info
Show-SqlObject-Info

if ($true -eq $tgtvdp.IsPresent) {
  Get-TgtVdp-Info $VdpIp $VdpUser $VdpPassword $ToExec.IsPresent
}

exit