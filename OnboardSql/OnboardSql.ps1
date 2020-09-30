# 
## File: OnboardSql.ps1
## Purpose: Script to automate the onboarding of the Sql Server.
#
# Version 1.0 Initial Release
# Version 1.1 Add disk info, improve script
# Version 1.2 add menu
# Version 1.3 add iscsi test
# Version 1.4 add password file support
# Version 1.5 improve menu, add iSCSI onboarding, improve unbounded message
# Version 1.6 improve VSS reporting
# Version 1.7 improve visual alerts
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

    To get a guided menu

.EXAMPLE
    PS > .\OnboardSql.ps1 -srcsql -tgtvdp -vdpip 10.10.10.1 -vdpuser cliuser -vdppasword TopSecret 

    To check the source SQL Server and target VDP appliance (IP address: 10.10.10.1) using the CLI user (cliuser - TopSecret). 

.EXAMPLE
    PS > .\OnboardSql.ps1 -srcsql -tgtvdp -vdpip 10.10.10.1 -vdpuser cliuser -passwordfile .\file.key

    To check the source SQL Server and target VDP appliance (IP address: 10.10.10.1) using the CLI user (cliuser - TopSecret) with a stored password file

.EXAMPLE
    PS > .\OnboardSql.ps1 -srcsql -tgtvdp -iscsitest -vdpip 10.10.10.1 -vdpuser cliuser -passwordfile .\file.key 

    To check the source SQL Server and target VDP appliance (IP address: 10.10.10.1) using the CLI user (cliuser - TopSecret) with a stored password file
    Also run the iSCSI test.

.EXAMPLE
    PS > .\OnboardSql.ps1 -srcsql -tgtvdp -vdpip 10.10.10.1 -vdpuser cliuser -vdppasword TopSecret -ToExec 

    To check the source SQL Server and target VDP appliance (IP address: 10.10.10.1) using the CLI user (cliuser - TopSecret). Also register the source SQL server with VDP appliance.

.NOTES   
    Name: OnboardSql.ps1
    Author: Michael Chew and Anthony Vandewerdt
    DateCreated: 3-April-2020
    LastUpdated: 30-Sept-2020
.LINK
    https://github.com/Actifio/powershell/blob/master/OnboardSql   
#>

[CmdletBinding()]
Param
( 
  [switch]$srcsql = $false,         
  [switch]$tgtvdp = $false,      
  [switch]$ToExec = $false,  
  [switch]$iscsitest = $false,  
  [string]$vdpip = "",           
  [string]$vdpuser = "",        
  [string]$vdppassword = "",
  [string]$passwordfile
)  ### Param

$ScriptVersion = "1.6"

function Get-SrcWin-Info ()
{
    Write-Host "Gathering information on Windows Host. "

    ## Find the Windows version on the source Windows Server
    $WinVer = Get-WmiObject -Class Win32_OperatingSystem | ForEach-Object -MemberName Caption
    $thisObject | Add-Member -MemberType NoteProperty -Name 'WindowsVersion' -Value $("$WinVer")

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

    # check powershell version
    [string]$psversionmajor = (Get-host).version.major 
    [string]$psversionminor = (Get-host).version.minor
    [string]$psversiongrab = $psversionmajor + "." + $psversionminor
    $thisObject | Add-Member -MemberType NoteProperty -Name PowerShellVersion -Value $psversiongrab

    # look for connector 
    if (! (Test-Path 'HKLM:\SOFTWARE\Actifio Inc')) {
    # Write-Host "Actifio Software is not installed on this host !!"
    $ConnectorVersion = $Null
    } else {
    $ConnectorVersion = (Get-ItemProperty 'HKLM:\SOFTWARE\Actifio Inc\UDSAgent').Version
    }
    $thisObject | Add-Member -MemberType NoteProperty -Name ConnectorVersion -Value $ConnectorVersion  
}

function Get-WinObject-DiskInfo ()
{
    Write-Host "Gathering information on Disk Usage. "
    $volumedata = Get-WmiObject -Class win32_volume  -Filter "(DriveType = '3')" 
    $volumedata = $volumedata | Where-Object label -ne "System Reserved" | sort-object name
    $vssobject = @()
        # Check if that drive letter has shadowstorage
    foreach ($drive in $volumedata) 
    {
        $deviceID = $drive.deviceID
        # Clean up the deviceID variable so it will be able to match results from gwmi win32_shadowstorage
        $deviceID = $deviceID.TrimStart("\\?\")
        $deviceID = "Win32_Volume.DeviceID=`"\\\\?\\" + $deviceID + "\`""
        $vssgrab = Get-WmiObject -Class win32_shadowstorage -ErrorAction SilentlyContinue | Where-Object {$_.Volume -eq $deviceID}
        $diffname = (Get-WmiObject -Class win32_volume | Where-Object {$_.__RELPATH -eq $vssgrab.DiffVolume}).Name
        if ($vssgrab.MaxSpace -eq "18446744073709551615")
        {
            $vss_maxspaceGiB = "Unbounded"
        }
        else {
            $vss_maxspaceGiB = [math]::round($vssgrab.MaxSpace/1GB, 2)
        }
        $vssobject += [pscustomobject]@{
            name = $drive.Name
            label = $drive.Label
            FreeSpacePerc = [math]::round($drive.FreeSpace/$drive.Capacity*100, 2)
            FreeSpaceGiB = [math]::round($drive.FreeSpace/1GB, 2)
            CapacityGiB = [math]::round($drive.Capacity/1GB, 2)
            vssdiff = $diffname
            vss_usedspaceGiB = [math]::round($vssgrab.UsedSpace/1GB, 2)
            vss_allocspaceGiB = [math]::round($vssgrab.AllocatedSpace/1GB, 2)
            vss_maxspaceGiB = $vss_maxspaceGiB
        }
    }
    $script:vssobject = $vssobject
}

function Get-SrcSql-Info ([string]$vdpip)
{
 

    if (($iscsitest.IsPresent) -and ($ToExec.IsPresent))
    {
        Write-Host "Ensuring all iSCSI related services are setup correctly."
        Start-Service msiscsi
        Set-Service msiscsi -startuptype "automatic"
        Set-NetFirewallRule -Name MsiScsi-In-TCP -Enabled True
        Set-NetFirewallRule -Name MsiScsi-Out-TCP -Enabled True
    }

    Write-Host "Gathering information on Sql Server Host. "
    ## Get the status of iSCSI service : Running, Stopped
    $iSCSIStatus = $(get-service msiscsi).status
    $thisObject | Add-Member -MemberType NoteProperty -Name iSCSIStatus -Value $("$iSCSIStatus")

    ## Get the status of firewall for iSCSI service : "Running", "Stopped"
    $iSCSIfirewall = Get-NetFirewallRule -DisplayGroup "iscsi Service"

    Get-NetFirewallProfile | Select-Object Name, Enabled | ForEach-Object { 
    $Label = $_.Name + "Firewall"
    $thisObject | Add-Member -MemberType NoteProperty -Name $Label  -Value ($_.Enabled).ToString()
    }

    ## $iSCSIfwIn.Enabled , $iscsifwOut.Enabled : "True"
    $iSCSIfwIn = $iSCSIfirewall | Where-Object {$_.Name -eq "MsiScsi-In-TCP"}
    $iscsifwOut = $iSCSIfirewall | Where-Object {$_.Name -eq "MsiScsi-Out-TCP"}

    $thisObject | Add-Member -MemberType NoteProperty -Name iSCSIfwInStatus -Value ($($iSCSIfwIn.Enabled)).ToString()
    $thisObject | Add-Member -MemberType NoteProperty -Name iSCSIfwOutStatus -Value ($($iSCSIfwOut.Enabled)).ToString()

    if (! (Test-Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server')) {
    $SQLInstalled = $False
    $SQLInstances = $Null
    } else {
    $SQLInstalled = $True
    $SQLInstances = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
    }
    $thisObject | Add-Member -MemberType NoteProperty -Name SqlInstances -Value $SQLInstances  
    $thisObject | Add-Member -MemberType NoteProperty -Name SqlInstalled -Value $SQLInstalled

    if ($vdpip -ne $null -And $vdpip -ne "") {
    $Pingable = Test-Connection $VDPIP -Count 1 -Quiet
    $thisObject | Add-Member -MemberType NoteProperty -Name Pingable -Value $Pingable    
    } else {
    $thisObject | Add-Member -MemberType NoteProperty -Name Pingable -Value $Null
    }

    $VssWriters = ""
    $VssWriters = @(vssadmin list writers | Select-String -Context 0,4 '^writer name:' | 
    Select @{Label="Writer"; Expression={$_.Line.Trim("'").SubString(14)}}, 
        @{Label="State"; Expression={$_.Context.PostContext[2].Trim().SubString(11)}},
        @{Label="LastError"; Expression={$_.Context.PostContext[3].Trim().SubString(12)}})

    $thisObject | Add-Member -MemberType NoteProperty -Name VssWriters -Value $VssWriters     

}      

##################################
# Function: Get-TgtVDP-Info
#
# Download the ActPowerCLI from GitHub
# 
##################################
function Get-TgtVDP-Info (
  [bool]$WillExec
)
{
    if  ((!($vdpip)) -and ($env:acthost))
    {
        $vdpip = $env:acthost
    }
    if  ((!($vdpip)) -and ($acthost))
    {
        $vdpip = $acthost
    }

    if (!($vdpip))
    {
        $vdpip = Read-Host "IP or Name of VDP Appliance";
    }

    Write-Host "Gathering information on VDP Appliance. "

    if  (! ( Test-Connection $vdpip -Count 2 -Quiet )) {
    Write-Host "Unable to ping / reach $vdpip .. "
    # exit 1
    }

    ## Ensure that the ActPowerCLI module is imported
    #
    $moduleins = get-module -listavailable -name ActPowerCLI
    if ($null -eq $moduleins) {
        #Import-Module ActPowerCLI
        Write-Host "ActPowerCLI Module not detected."
        exit 1
    }

    if ( (!($env:ACTSESSIONID ))  -and (!($ACTSESSIONID)) )
    {
        if ($passwordfile)
        { 
            if ((Test-Path $passwordfile) -eq "True")
            {
                $rc = connect-act -acthost $vdpip -actuser $VDPUser -passwordfile $passwordfile -ignorecerts
            }
            else 
            {
                Write-host "Cannot find password file $passwordfile"
                exit 1    
            }
        }
        else 
        {
            $rc = connect-act -acthost $vdpip -actuser $vdpuser -password $vdppassword -ignorecerts
        }
    }

    if ( (!($env:ACTSESSIONID ))  -and (!($ACTSESSIONID)) ) {
    Write-Host "Unable to connect to VDP appliance $vdpip .. "
    exit 1
    }

    write-Host "`n--------- S T A T U S      R E P O R T      P A R T 2 ----------------------------------`n"  
    write-host "`n* TEST:  Testing the connection from VDP appliance to SQL Server $(($thisObject).IPAddress) on port 5106 (connector port)"
    $rc = udstask testconnection -type tcptest -targetip $thisObject.IPAddress -targetport 5106

    if ($rc.result)
    {
        if ( $(($rc).result).Contains("succeeded!") ) {
        write-host "Passed: VDP is able to communicate with the SQL Server $(($thisObject).IPAddress) on port 5106"
        } else {
        write-host "---> Failed: VDP unable to communicate with the SQL Server $(($thisObject).IPAddress) on port 5106"
        }
    }
    elseif  ($rc.errorcode)
    {
        $rc
        exit 1
    }

    write-host "`n* TEST:  Checking if this host is already defined to the VDP Appliance"
    $hostid = $(udsinfo lshost | Where-Object { $_.hostname -eq $(($thisObject).ComputerName) } | Select-Object Id).Id
    if ($hostid)
    {
        write-host "Passed:  $(($thisObject).ComputerName) is already defined in the VDP appliance as host ID $hostid. No registration required! "
    }
    if ((!($hostid)) -and ($env:USERDNSDOMAIN))
    {
        $hostid = $(udsinfo lshost | Where-Object { $_.hostname -eq $(($thisObject).FQDN) } | Select-Object Id).Id
        if ($hostid)
        {
            write-host "Passed:  $(($thisObject).FQDN) is already defined in the VDP appliance as host ID $hostid. No registration required! "
        }
    }

    if ( (!($hostid)) -and ($true -eq $WillExec))
    {
        write-host "`nRegistering the $(($thisObject).ComputerName) with Actifio VDP appliance $vdpip `n"
        $cmd = "udstask mkhost -hostname " + $(($thisObject).ComputerName) + " -ipaddress " + $(($thisObject).IPAddress) + " -type generic "
        # write-host "> $cmd"
        if ($true -eq $WillExec) 
        {
            Invoke-Expression $cmd
        } 

        $HostId = $(udsinfo lshost | Where-Object { $_.hostname -eq $(($thisObject).ComputerName) } | Select-Object Id).Id
        write-host "`nUpdating the description for the $(($thisObject).ComputerName) entry in Actifio VDP appliance $vdpip `n"
        $cmd = "udstask chhost -description " + [char]34 + "Added by OnboardSql script" + [char]34 + $hostid
        # write-host "> $cmd"
        if ($true -eq $WillExec) 
        {
            Invoke-Expression $cmd
        } 
    } 
    
    if ( (!($hostid)) -and ($false -eq $WillExec))
    {
        write-host "`n---> Failed: Did not find a host definition matching $(($thisObject).ComputerName) on Actifio VDP appliance $vdpip `n"
        return
    }

    if ($iscsitest)
    {
        write-host "`n* TEST:  Performing an iSCSI test on $(($thisObject).ComputerName) from VDP appliance $vdpip : `n"
        $cmd = "udstask iscsitest -host " + $HostId 
        Invoke-Expression $cmd | Format-Table *
    } 

    if ($true -eq $WillExec) {   
        write-host "`nPerforming an application discovery on $(($thisObject).ComputerName) and updating the information in VDP appliance $vdpip `n"
        $cmd = "udstask appdiscovery -host " + $hostid
        # write-host "> $cmd"
        if ($true -eq $WillExec) {
            Invoke-Expression $cmd | Format-Table *
        } 
    }


    write-host "`n* TEST:  Listing all applications discovered on $(($thisObject).ComputerName) stored in VDP appliance $vdpip : `n"
    $cmd = "udsinfo lsapplication | where { `$`_.HostId -eq $HostId } | Select-Object AppName, AppType "
    #write-host "> $cmd"
    #if ($true -eq $WillExec) {
        Invoke-Expression $cmd | Sort-Object apptype,appname | Format-Table * 
    #} 

    if (($thisObject).'ConnectorVersion') 
    {
        write-host "`n* TEST:  Checking Connector version of $(($thisObject).ComputerName) compared to latest available on VDP appliance $vdpip"
        $connectorgrab = reportconnectors -a $hostid
        if ($connectorgrab.VersionCheck -eq "Current Release")
        {
            write-host "Passed:  Connector is on the Current Release" $connectorgrab.AvailableVersion
        }   
        elseif ($connectorgrab.VersionCheck -eq "Newer Version")
        {
            write-host "Partial:  Installed Connector ($thisObject).'ConnectorVersion' is on a higher release than the VDP Applianceversion" $connectorgrab.AvailableVersion
        }
        elseif ( $connectorgrab.VersionCheck -eq "Upgrade Needed")
        {
            write-host "---> Failed: Connector is downlevel, version" $connectorgrab.AvailableVersion "is available"
            if  ($false -eq $WillExec)
            {
                write-host "             Upgrade by running:    udstask upgradehostconnector -hosts $hostid"
                write-host "             Wait a few minutes for the upgrade to complete before testing again"
            }
            else {
                write-host "Upgrading Connector to $connectorgrab.AvailableVersion. Wait a few minutes for the upgrade to complete before testing again"
                udstask upgradehostconnector -hosts $hostid
            }
        }
        else 
        {
            Write-Host "Connector version not found"
        }
    }

    write-Host "`n---------------------------------------------------------------------------`n"

    # Disconnect-Act -quiet
}      

##################################
# Function: Show-Usage
#
##################################
function Show-Usage ()
{
    write-host "Usage: .\OnboardSql.ps1 [ -srcsql ] [ -tgtvdp ] [ -ToExec ] [ -vdpip <VDP IP appliance> [ -vdpuser <VDP CLI user> ] [ -vdppassword <VDP password> ] [ -passwordfile <stored password> ]`n"
    write-host " get-help .\OnboardSql.ps1 -examples"
    write-host " get-help .\OnboardSql.ps1 -detailed"
    write-host " get-help .\OnboardSql.ps1 -full"    
    exit 0
}     

function Show-WinObject-Info ()
{
  write-Host "`n--------- S T A T U S      R E P O R T      P A R T 1 ----------------------------------`n"  
  write-Host "            Computer Name: $(($thisObject).ComputerName) "
  write-Host "               IP Address: $(($thisObject).IPAddress) "
  write-Host "                     FQDN: $(($thisObject).FQDN) "  
  write-Host "                       OS: $(($thisObject).'WindowsVersion')"
  write-Host "       PowerShell Version: $(($thisObject).'PowerShellVersion')"
  write-Host "        Actifio Connector: $(($thisObject).'ConnectorVersion')`n"
  write-Host "`n---------------------------------------------------------------------------`n"
  
}
function Show-WinObject-DiskInfo ()
{
    write-host "Drive Information:"
    if ($vssobject)
    {
        $vssobject | Format-Table *
    }
    else 
    {
        write-host "No Drive Information was found" -ForegroundColor red -BackgroundColor white
    }
    write-Host "`n---------------------------------------------------------------------------`n"
}

##################################
# Function: Show-SqlObject-Info
#
##################################
function Show-SqlObject-Info (
  [string]$vdpip
)
{
  write-Host "          Domain Firewall: $(($thisObject).DomainFirewall) "
  write-Host "         Private Firewall: $(($thisObject).PrivateFirewall) "
  write-Host "          Public Firewall: $(($thisObject).PublicFirewall) "  
  write-Host "   iSCSI FireWall Inbound: $(($thisObject).iSCSIfwInStatus) "
  write-Host "  iSCSI FireWall Outbound: $(($thisObject).iSCSIfwOutStatus)`n"  

  if ($vdpip -ne $null -And $vdpip -ne "") {
    if ( Test-Connection $vdpip -Count 2 -Quiet ) {
      write-Host "  Actifio VDP Ip Pingable: True "
    } else {
      write-Host "  Actifio VDP Ip Pingable: False " -ForegroundColor red -BackgroundColor white
    }    
  }

  if ($False -eq $(($thisObject).SqlInstalled)) {
    write-Host "            SQL Server SW: Not Installed " -ForegroundColor red -BackgroundColor white
  } else {
    write-Host "            SQL Server SW: Installed "
  }
  if ($null -eq  $(($thisObject).SqlInstances)) {
    write-Host "             SQL Instance: No Instances Created " -ForegroundColor red -BackgroundColor white
  } else {
    $(($thisObject).SqlInstances) | ForEach-Object { 
    write-Host "             SQL Instance: $_ "  
      }
  }
  if ($null -eq  $(($thisObject).VssWriters)) {
    write-Host "              VSS Writers: Not Installed " -ForegroundColor red -BackgroundColor white
  } 
  else 
  {
	# if we cannot find SqlServerWriter then we need to highlight this
    $sqlvsscheck = $($(($thisObject).VssWriters) | where-object { $_.Writer -eq "SqlServerWriter" } | select Writer).writer
    if ($sqlvsscheck -eq $null)
    {
        write-Host "              VSS Writers: SqlServerWriter not found!" -ForegroundColor red -BackgroundColor white
    }
    $(($thisObject).VssWriters) | ForEach-Object { 
        if ($_.State -eq "Stable")
        {
            write-Host "     VSS Writer [ State ]: $($_.Writer) [ $($_.State) ] ( $($_.LastError) )"  
        } 
        elseif ($_.State -eq "Failed")
        {
            write-Host "     VSS Writer [ State ]: $($_.Writer) [ $($_.State) ] ( $($_.LastError) )"  -ForegroundColor red -BackgroundColor white
        } 
        else 
        {
            write-Host "     VSS Writer [ State ]: $($_.Writer) [ $($_.State) ] ( $($_.LastError) )"  -ForegroundColor Black -BackgroundColor white
        } 
    }
  }
    write-Host "`n---------------------------------------------------------------------------`n"

}     ### end of function 


##############################
#
#  M A I N    B O D Y
#
##############################

if (($false -eq $srcsql.IsPresent) -And ($false -eq $tgtvdp.IsPresent)) {
    Clear-Host
    Write-Host "This is the Actifio Onboarding tool for MicroSoft SQL.   You have have several choices:"
    Write-Host ""
    Write-Host "1`: CHECK SQL - Check all components required on the SQL Server (default)"
    Write-Host "2`: CHECK NETWORK - Check network connectivity for this host to a VDP Appliance (needs ActPowerCLI PowerShell Module installed)"
    Write-Host "3`: CHECK NETWORK & ISCSI - Check connectivity for this host to a VDP Appliance (needs ActPowerCLI PowerShell Module installed)"
    Write-Host "4`: CHECK 1 & 2 (recommended if sharing this information with Actifio and host iSCSI is NOT in use)"
    Write-Host "5`: CHECK 1 & 3 (recommended if sharing this information with Actifio and host iSCSI is in use)"
    Write-Host "6`: ONBOARD WITHOUT ISCSI - Onboard this host to a VDP Appliance (needs ActPowerCLI PowerShell Module installed"
    Write-Host "7`: ONBOARD WITH ISCSI - Onboard this host to a VDP Appliance with iSCSI (needs ActPowerCLI PowerShell Module installed"
    Write-Host "8`: Show CLI options to run this function without using this menu"
    Write-Host ""
    [int]$userselection = Read-Host "Please select from this list (1-8)"
    if ($userselection -eq "") { $userselection = 1 }
    if ($userselection -eq 1) {  $srcsql = $TRUE }
    if ($userselection -eq 2) {  $tgtvdp = $TRUE }
        $iscsitest = $FALSE}
    if ($userselection -eq 3) {  $tgtvdp = $TRUE 
        $iscsitest = $TRUE}
    if ($userselection -eq 4) {  $tgtvdp = $TRUE 
        $iscsitest = $FALSE
        $srcsql = $TRUE}
    if ($userselection -eq 5) {  $tgtvdp = $TRUE 
        $iscsitest = $TRUE
        $srcsql = $TRUE}
    if ($userselection -eq 6) {  $tgtvdp = $TRUE  
        $ToExec = $TRUE 
        $iscsitest = $FALSE}
    if ($userselection -eq 7) 
    {
        $srcsql = $TRUE  
        $tgtvdp = $TRUE  
        $ToExec = $TRUE 
        $iscsitest = $TRUE}
    if ($userselection -eq 8) {  Show-Usage  }

$hostVersionInfo = (get-host).Version.Major
    
## Create an object based on the PSObject class
$thisObject = New-Object -TypeName psobject 


Get-SrcWin-Info
if ($true -eq $srcsql.IsPresent) {
  Get-WinObject-DiskInfo
  Get-SrcSql-Info $vdpip
}

Show-WinObject-Info
if ($true -eq $srcsql.IsPresent) 
{
    Show-WinObject-DiskInfo
    Show-SqlObject-Info $vdpip
}
if ($true -eq $tgtvdp.IsPresent) 
{
    Get-TgtVDP-Info $ToExec.IsPresent
}



exit
