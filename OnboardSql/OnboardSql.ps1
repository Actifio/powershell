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
# Version 1.8 added HTML output
# Version 1.9 Improved HTML output
# Version 1.10 handle PowerShell 3.0.  addded automount and trim/unmap tests
# Version 1.11 better agent health checks
# Version 1.12 Ignore ReFS Disable Delete, handle iSCSI service using non-English name
# Version 1.13 add warning about DBs with leading/trailing spaces in name.  Print script version.  Use SQL PS module to learn Instance Names
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
    LastUpdated: 16-Nov-2020
.LINK
    https://github.com/Actifio/powershell/blob/main/OnboardSql   
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

$ScriptVersion = "1.13"

function Get-SrcWin-Info ()
{
    Write-Host "Gathering information on Windows Host. "

    # script version!
    $thisObject | Add-Member -MemberType NoteProperty -Name OnBoardSQLScriptVersion -Value $("$ScriptVersion")

    ## Find the Windows version on the source Windows Server
    $WinVer = Get-WmiObject -Class Win32_OperatingSystem | ForEach-Object -MemberName Caption
    $thisObject | Add-Member -MemberType NoteProperty -Name 'WindowsVersion' -Value $("$WinVer")

    ## Find the source Windows Server computername
    $thisObject | Add-Member -MemberType NoteProperty -Name ComputerName -Value $("$env:COMPUTERNAME")

    ## Find the source Windows Server FQDN
    $CurrentFQDN = [System.Net.DNS]::GetHostByName($Null).HostName
    $thisObject | Add-Member -MemberType NoteProperty -Name FQDN -Value $("$CurrentFQDN")
    if ($hostVersionInfo -gt 3)
    {
        ## Find the source Windows Server IP address
        $CurrentIP = ( Get-NetIPConfiguration |
        Where-Object {
            $null -ne $_.IPv4DefaultGateway -And
            $_.NetAdapter.Status -ne "Disconnected"
        } ).IPv4Address.IPAddress | select-object -first 1
        $thisObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value $("$CurrentIP")
    }

    # check powershell version
    [string]$psversionmajor = (Get-host).version.major 
    [string]$psversionminor = (Get-host).version.minor
    [string]$psversiongrab = $psversionmajor + "." + $psversionminor
    $thisObject | Add-Member -MemberType NoteProperty -Name PowerShellVersion -Value $psversiongrab

    # look for actpowercli
    $actpowercligrab = Get-Module -ListAvailable -Name ActPowerCLI -ErrorAction SilentlyContinue | Select-Object -Property Version
    if ($actpowercligrab.version)
    {
        $thisObject | Add-Member -MemberType NoteProperty -Name ActPowerCLIVersion -Value $actpowercligrab.version
    }
    else 
    {
        $thisObject | Add-Member -MemberType NoteProperty -Name ActPowerCLIVersion -Value "NotInstalled"
    }


    # look for connector 
   # look for connector 
   if (! (Test-Path 'HKLM:\SOFTWARE\Actifio Inc')) 
   {
       # Write-Host "Actifio Software is not installed on this host !!"
       $ConnectorVersion = "NotInstalled"
       $AAMServiceInstanced = "NotInstalled"
   } 
   else 
   {
       $ConnectorVersion = (Get-ItemProperty 'HKLM:\SOFTWARE\Actifio Inc\UDSAgent').Version
       $ConnectorStatus = (Get-Service -name UDSAgent).Status
       $thisObject | Add-Member -MemberType NoteProperty -Name ActifioConnectorStatus -Value $ConnectorStatus
       if (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\AAMService') 
       {
           $AAMServiceInstanced = "Installed"
           $aamstatus = (Get-Service -name AAMService).Status
           $thisObject | Add-Member -MemberType NoteProperty -Name ActifioActivityMonitorStatus -Value $aamstatus
       }
       else 
       {
           $AAMServiceInstanced = "NotInstalled"
       }
   }
   $thisObject | Add-Member -MemberType NoteProperty -Name ActifioConnectorVersion -Value $ConnectorVersion
   $thisObject | Add-Member -MemberType NoteProperty -Name ActifioActivityMonitor -Value $AAMServiceInstanced   

    # look for automount 
    $automountgrab = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\MountMgr'
    if ($automountgrab.NoAutoMount)
    {
        if ($automountgrab.NoAutoMount -eq 1)
        {
            $thisObject | Add-Member -MemberType NoteProperty -Name AutoMount -Value "Disabled"
        }
        else {
            $thisObject | Add-Member -MemberType NoteProperty -Name AutoMount -Value "Enabled"
        }
    }
    else
    {
        $thisObject | Add-Member -MemberType NoteProperty -Name AutoMount -Value "Enabled"
    }

    # look for DisableDeleteNotify
    $disabledelete = fsutil behavior query DisableDeleteNotify
    if ($($disabledelete | measure-object -line).lines -gt 1)
    {
        $disabledelete = fsutil behavior query DisableDeleteNotify NTFS
        if ($disabledelete  -eq "NTFS DisableDeleteNotify = 0")
        {
            $thisObject | Add-Member -MemberType NoteProperty -Name TrimUnmapFeature -Value "Enabled"
        }
        else 
        {
            $thisObject | Add-Member -MemberType NoteProperty -Name TrimUnmapFeature -Value "Disabled"
        }
    } 
    else 
    {
        if ($disabledelete  -eq "DisableDeleteNotify = 0")
        {
            $thisObject | Add-Member -MemberType NoteProperty -Name TrimUnmapFeature -Value "Enabled"
        }
        else 
        {
            $thisObject | Add-Member -MemberType NoteProperty -Name TrimUnmapFeature -Value "Disabled"
        }
    }
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
 
    Write-Host "Gathering information on Sql Server Host. "
    ## Get the status of iSCSI service : Running, Stopped
    $iSCSIStatus = $(get-service msiscsi).status
    $thisObject | Add-Member -MemberType NoteProperty -Name iSCSIStatus -Value $("$iSCSIStatus")


    if ($hostVersionInfo -gt 3)
    {   
        if (($iscsitest.IsPresent) -and ($ToExec.IsPresent))
        {
            Write-Host "Ensuring all iSCSI related services are setup correctly."
            Start-Service msiscsi
            Set-Service msiscsi -startuptype "automatic"
            Set-NetFirewallRule -Name MsiScsi-In-TCP -Enabled True
            Set-NetFirewallRule -Name MsiScsi-Out-TCP -Enabled True
        }
        ## Get the status of firewall for iSCSI service : "Running", "Stopped"
        $iSCSIfirewall = Get-NetFirewallRule -DisplayGroup "iscsi *"

        Get-NetFirewallProfile | Select-Object Name, Enabled | ForEach-Object { 
        $Label = $_.Name + "Firewall"
        $thisObject | Add-Member -MemberType NoteProperty -Name $Label  -Value ($_.Enabled).ToString()
        }

        ## $iSCSIfwIn.Enabled , $iscsifwOut.Enabled : "True"
        $iSCSIfwIn = $iSCSIfirewall | Where-Object {$_.Name -eq "MsiScsi-In-TCP"}
        $iscsifwOut = $iSCSIfirewall | Where-Object {$_.Name -eq "MsiScsi-Out-TCP"}

        $thisObject | Add-Member -MemberType NoteProperty -Name iSCSIfwInStatus -Value ($($iSCSIfwIn.Enabled)).ToString()
        $thisObject | Add-Member -MemberType NoteProperty -Name iSCSIfwOutStatus -Value ($($iSCSIfwOut.Enabled)).ToString()
    }
    if (! (Test-Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server')) {
    $SQLInstalled = $False
    $SQLInstances = $Null
    } else {
    $SQLInstalled = $True
    Import-ActSqlModule
    if (Test-Path -Path SQLSERVER:\SQL) {
        $SQLInstances = $env:COMPUTERNAME | Foreach-Object {Get-ChildItem -Path "SQLSERVER:\SQL\$_"}
    } else {
        $SQLInstances = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances
    }
    }
    $thisObject | Add-Member -MemberType NoteProperty -Name SqlInstances -Value $SQLInstances  
    $thisObject | Add-Member -MemberType NoteProperty -Name SqlInstalled -Value $SQLInstalled

    if ($vdpip -ne $null -And $vdpip -ne "") {
    $Pingable = Test-Connection $VDPIP -Count 1 -Quiet
    $thisObject | Add-Member -MemberType NoteProperty -Name Pingable -Value $Pingable    se
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

function Import-ActSqlModule
{
    Write-host "Importing SqlServer PowerShell module"
    if ( -not(Get-Module -Name SqlServer) -and (-not(Get-Module -Name SQLPS)))
    {
        Write-host "SqlServer or SQLPS PowerShell module or snapin not currently loaded"
        if (Get-Module -Name SqlServer -ListAvailable)
        {
            Write-host "SqlServer PowerShell module found"
            
            Push-Location
            Write-host "Storing the current location: '$((Get-Location).Path)'"
            
            $policy = Get-ExecutionPolicy
            Write-host "Existing policy is $($policy)"
            
            if($policy -ne "ByPass")
            {
                Set-ExecutionPolicy  ByPass  
                Write-host "Set Existing policy as ByPass"        
            }
            
            Import-Module -Name SqlServer -DisableNameChecking
            if( !$? )  
            {
                Write-host "The SqlServer PowerShell module cannot be loaded"     
            }
            else {
                Write-host "SqlServer PowerShell module successfully loaded"
            }    
            if($policy -ne "ByPass")
            {
                Set-ExecutionPolicy  $policy
                Write-host "Reset Existing policy as $($policy)"
            }

            Pop-Location
            Write-host "Changing current location to previously stored location: '$((Get-Location).Path)'"
        }
        elseif ((Get-Module -Name SQLPS -ListAvailable) -and ($hostVersionInfo -lt 6))
        {
            Write-host "SQLPS PowerShell module found"
            
            Push-Location
            Write-host "Storing the current location: '$((Get-Location).Path)'"
            
            $policy = Get-ExecutionPolicy
            Write-host "Existing policy is $($policy)"
            
            Set-ExecutionPolicy  ByPass  
            Write-host "Set Existing policy as ByPass"        
            
            Import-Module -Name SQLPS -DisableNameChecking 
            if( !$? )  
            {
                Write-host "The SQLPS PowerShell module cannot be loaded"
            }
            else 
            {
                Write-host "SQLPS PowerShell module successfully loaded"
            }
            Set-ExecutionPolicy  $policy
            Write-host "Reset Existing policy as $($policy)"
            
            Pop-Location
            Write-host "Changing current location to previously stored location: '$((Get-Location).Path)'"
        }
        else
        {
            Write-host "SqlServer or SQLPS PowerShell module not found"
        }
    }
    else
    {
        Write-host "SQL PowerShell module already loaded"
    }
    
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
        $iscsitestout = Invoke-Expression $cmd 
        $iscsitestout | Format-Table *
    } 

    if ($true -eq $WillExec) {   
        write-host "`nPerforming an application discovery on $(($thisObject).ComputerName) and updating the information in VDP appliance $vdpip `n"
        $cmd = "udstask appdiscovery -host " + $hostid
        # write-host "> $cmd"
        if ($true -eq $WillExec) {
            $appdiscovery = Invoke-Expression $cmd 
            $appdiscovery | format-table *
        } 
    }


    write-host "`n* TEST:  Listing all applications discovered on $(($thisObject).ComputerName) stored in VDP appliance $vdpip : `n"
    $cmd = "udsinfo lsapplication | where { `$`_.HostId -eq $HostId } | Select-Object ID, AppName, AppType "

    $applist = Invoke-Expression $cmd | Sort-Object id, apptype,appname 
    $applist| Format-Table * 
    

    if (($thisObject).'ActifioConnectorVersion') 
    {
        write-host "`n* TEST:  Checking Connector version of $(($thisObject).ComputerName) compared to latest available on VDP appliance $vdpip"
        $connectorgrab = reportconnectors -a $hostid
        if ($connectorgrab.VersionCheck -eq "Current Release")
        {
            write-host "Passed:  Connector is on the Current Release" $connectorgrab.AvailableVersion
        }   
        elseif ($connectorgrab.VersionCheck -eq "Newer Version")
        {
            write-host "Partial:  Installed Connector ($thisObject).'ActifioConnectorVersion' is on a higher release than the VDP Applianceversion" $connectorgrab.AvailableVersion
        }
        elseif ( $connectorgrab.VersionCheck -eq "Upgrade Needed")
        {
            write-host "---> Failed: Connector is downlevel, version" $connectorgrab.AvailableVersion "is available"
            write-host "             Upgrade by running:    udstask upgradehostconnector -hosts $hostid"
            write-host "             Wait a few minutes for the upgrade to complete before testing again"
        }
        else 
        {
            Write-Host "Connector version not found"
        }
    }

    write-Host "`n---------------------------------------------------------------------------`n"

    # Disconnect-Act -quiet
    New-SQLHTMLReport
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
  write-Host "             Computer Name: $(($thisObject).ComputerName) "
  write-Host "                IP Address: $(($thisObject).IPAddress) "
  write-Host "                      FQDN: $(($thisObject).FQDN) "  
  write-Host "                        OS: $(($thisObject).'WindowsVersion')"
  write-Host "        PowerShell Version: $(($thisObject).'PowerShellVersion')"
  write-Host "Onboard SQL Script Version: $(($thisObject).'OnBoardSQLScriptVersion')"
  write-Host "       ActPowerCLI Version: $(($thisObject).'ActPowerCLIVersion')"
  write-Host "         Actifio Connector: $(($thisObject).'ActifioConnectorVersion')"
  write-Host "  Actifio Activity Monitor: $(($thisObject).'ActifioActivityMonitor')"
  write-Host "                Auto Mount: $(($thisObject).'AutoMount')"
  write-Host "    Trim and unmap feature: $(($thisObject).'TrimUnmapFeature')`n"
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
    if ($hostVersionInfo -gt 3)  
    {
        write-Host "          Domain Firewall: $(($thisObject).DomainFirewall) "
        write-Host "         Private Firewall: $(($thisObject).PrivateFirewall) "
        write-Host "          Public Firewall: $(($thisObject).PublicFirewall) "  
        write-Host "   iSCSI FireWall Inbound: $(($thisObject).iSCSIfwInStatus) "
        write-Host "  iSCSI FireWall Outbound: $(($thisObject).iSCSIfwOutStatus)`n"
    }  

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
    $sqlvsscheck = $($(($thisObject).VssWriters) | where-object { $_.Writer -eq "SqlServerWriter" } | Select-Object Writer).writer
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

##################################
# Function: New-HTMLReport 
#
##################################
function New-SQLHTMLReport
{
    $ComputerName = "<h1>Computer name: $env:computername</h1>"

    
    $OSinfo = $thisobject | ConvertTo-Html -As List -Property WindowsVersion,FQDN,IPAddress,PowerShellVersion,OnBoardSQLScriptVersion,ActPowerCLIVersion,ActifioConnectorVersion,ActifioActivityMonitor,AutoMount,TrimUnmapFeature -Fragment -PreContent "<h2>Operating System Information</h2>"

    # if AAM is not installed, we complain.  Note we complain even if Connector is NOT installed, bit this reminds user to enable it!
    if ($thisobject.ActifioActivityMonitor -eq "NotInstalled")
    {
        $aaminfo = $thisobject | ConvertTo-Html -As List -Property ActifioActivityMonitor -Fragment -PreContent "<h2>Actifio Activity Monitor</h2>" -PostContent "<p> The Actifio Activity Monitor needs to be installed.<br>Install/Reinstall the Actifio Connector and use the dropdown to enable the Change Tracking Driver<p>"
    }
    if ($thisobject.ActifioConnectorStatus) 
    {
        if ($thisobject.ActifioActivityMonitorStatus) 
        {
            if (($thisobject.ActifioActivityMonitorStatus -ne 'Running') -or ($thisobject.ActifioConnectorStatus -ne 'Running'))
            {
                $udsagentstatusinfo = $thisobject | ConvertTo-Html -As List -Property ActifioConnectorStatus,ActifioActivityMonitorStatus -Fragment -PreContent "<h2>Actifio Connector Status</h2>" -PostContent "<p> The Actifio Connector software AAMService or UDSAgent is not running..<br>Start services.msc and make sure both services are running<p>"
            }
        }
        else
        {
            if ($thisobject.ActifioConnectorStatus -ne 'Running')
            {
                $udsagentstatusinfo = $thisobject | ConvertTo-Html -As List -Property ActifioConnectorStatus -Fragment -PreContent "<h2>Actifio Connector Status</h2>" -PostContent "<p>The Actifio Connector software UDSAgent is not running..<br>Start services.msc and start it<p>"
            }
        }
    }


    if ($thisobject.AutoMount -eq "Enabled")
    {
        $automountinfo = $thisobject | ConvertTo-Html -As List -Property AutoMount -Fragment -PreContent "<h2>AutoMount Setting</h2>" -PostContent "<p> Actifio recommend AutoMount be disabled.<br>Start 'diskpart', then issue 'automount disable'<br> Reference KB: 000044847 and 000025867.<p>"
    }


    if ($thisobject.TrimUnmapFeature -eq "Enabled")
    {
        $TrimUnmapFeatureInfo = $thisobject | ConvertTo-Html -As List -Property TrimUnmapFeature -Fragment -PreContent "<h2>Trim and UnMap Feature Setting</h2>" -PostContent "<p>For very large disks, this setting may need to be disabled for the first snapshot<br> Reference KB: 000045385<p>"
    }
    

    if ($vssobject)
    {
        $driveinfo = $vssobject | ConvertTo-Html -Fragment -PreContent "<h2>Drive Information</h2>" -PostContent "<p> If FreeSpacePerc is less than 10% then consider using a vssdiff drive.<br> Reference KB: 000010287 and 000045141.<p>"
    }
    if ($hostVersionInfo -gt 3)
    {
        $firewallinfo = $thisobject | ConvertTo-Html -As List -Property DomainFirewall,PrivateFirewall,PublicFirewall,iSCSIfwInStatus,iSCSIfwOutStatus -Fragment -PreContent "<h2>Firewall Information</h2>"  -PostContent "<p>Result from:  Get-NetFirewallRule <br>Reference KB:  000039102<p>"
    }
    $sqlobject = New-Object -TypeName psobject 

    if ($False -eq $(($thisObject).SqlInstalled)) {
        $sqlobject | Add-Member -MemberType NoteProperty -Name 'SqlInstalled' -Value "No"
      } else {
        $sqlobject | Add-Member -MemberType NoteProperty -Name 'SqlInstalled' -Value "Yes"
      }
      if ($null -eq  $(($thisObject).SqlInstances)) {
        $sqlobject | Add-Member -MemberType NoteProperty -Name 'SqlInstances' -Value "No Instances Created"
      } else {
        $sqlobject | Add-Member -MemberType NoteProperty -Name 'SqlInstances' -Value ""
            $(($thisObject).SqlInstances) | ForEach-Object { 
                $sqlobject.SqlInstances = $sqlobject.SqlInstances + "  " + $_
                $i++
            }
      }
      if  ($(($thisObject).VssWriters)) 
      {
        # if we cannot find SqlServerWriter then we need to highlight this
        $sqlvsscheck = $($(($thisObject).VssWriters) | where-object { $_.Writer -eq "SqlServerWriter" } | Select-Object Writer).writer
        if ($sqlvsscheck -eq $null)
        {
            $sqlobject | Add-Member -MemberType NoteProperty -Name 'SqlServerWriter' -Value "Not found!" 
        }
        else 
        {
            $sqlobject | Add-Member -MemberType NoteProperty -Name 'SqlServerWriter' -Value "Found"
        }
      }
      else 
      {
        $sqlobject | Add-Member -MemberType NoteProperty -Name 'SqlServerWriter' -Value "Not found!" 
      }

    if ($sqlobject.SqlServerWriter -eq "Found")
    {
        $sqlinfo = $sqlobject | ConvertTo-Html -As List -Property SqlInstalled,SqlInstances,SqlServerWriter -Fragment -PreContent "<h2>SQL Information</h2>" 
    }  
    else 
    {
        $sqlinfo = $sqlobject | ConvertTo-Html -As List -Property SqlInstalled,SqlInstances,SqlServerWriter -Fragment -PreContent "<h2>SQL Information</h2>" -PostContent " <p>If the  SqlServerWriter is Not Found, then SQL Server is not installed or the SQL Server VSS Writer may be in a stopped state. <br>Reference KB: 000010284.<p><p>If the  SqlServerWriter is missing from 'vssadmin list writers', check for database names with leading or trailing spaces <br>Reference KB: 000045398.<p>"
    }
    

    $vssinfo = ($thisObject).VssWriters | ConvertTo-Html -Fragment -PreContent "<h2>VSSWriter Information</h2>" -PostContent  "<p>Result from: vssadmin list writers <br>Reference KB: 000010284 <p>"

    if ($tgtvdp -eq $FALSE)
    {
        #The command below will combine all the information gathered into a single HTML report
        $Report = ConvertTo-HTML -Body "$ComputerName $OSinfo $driveinfo $firewallinfo $sqlinfo $vssinfo $udsagentstatusinfo $aaminfo $automountinfo $TrimUnmapFeatureInfo" -Title "SQL Health Check Report"  -PostContent "<p>Report created: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))<p>"

        #The command below will generate the report to an HTML file
        $Report | Out-File .\SQL-Health-Check-Report.html
        write-host "Results output to: SQL-Health-Check-Report.html "
    }
    else 
    {
        if ($iscsitestout)
        {
            $iscsitestouthtml = $iscsitestout | ConvertTo-Html -Property iSCSIPort,Test,Status,Hint -Fragment -PreContent "<h2>iSCSI Test Result</h2>"  -PostContent "<p> Result from:  udstask iscsitest <p>"
        }
        if ($appdiscovery)
        {
            $appdiscoveryhtml = $appdiscovery | ConvertTo-Html -Property id,appname,exists,new,missing,saved -Fragment -PreContent "<h2>Application Discovery Result</h2>" -PostContent "<p> Result from:  udstask appdiscovery <p>"
        }
        if ($applist)
        {
            $applisthtml = $applist | ConvertTo-Html -Property id, AppName,AppType -Fragment -PreContent "<h2>Discovered Applications</h2>" -PostContent "<p> Result from: udsinfo lsapplication <p>"
        }

        if ($connectorgrab.VersionCheck)
        {
            if ($connectorgrab.VersionCheck -eq "Current Release")
            {
                $connectortest = $connectorgrab | ConvertTo-Html -Property InstalledVersion,AvailableVersion,VersionCheck -PreContent "<h2>Actifio Connector Version Check</h2>" -PostContent "<p> Result from: reportconnectors <p>"
            }
            if ($connectorgrab.VersionCheck -eq "Upgrade Needed")
            {
                $connectortest = $connectorgrab | ConvertTo-Html -Property InstalledVersion,AvailableVersion,VersionCheck -PreContent "<h2>Actifio Connector Version Check</h2>" -PostContent "<p> Result from: reportconnectors<br>  Connector is downlevel, please upgrade <p>"
            }
            if ($connectorgrab.VersionCheck -eq "Newer Version")
            {
                $connectortest = $connectorgrab | ConvertTo-Html -Property InstalledVersion,AvailableVersion,VersionCheck -PreContent "<h2>Actifio Connector Version Check</h2>" -PostContent "<p> Result from: reportconnectors br>  Connector is uplevel to the Appliance, this may cause unexpected issues <p>"
            }
        }

        if ($srcsql -eq $TRUE)
        {
            $Report = ConvertTo-HTML -Body "$ComputerName $OSinfo $driveinfo $firewallinfo $sqlinfo $vssinfo $udsagentstatusinfo $aaminfo $TrimUnmapFeatureInfo $connectortest $iscsitestouthtml $appdiscoveryhtml $applisthtml" -Title "SQL Onboarding Report"  -PostContent "<p>Report created: $(Get-Date)<p>"
        }
        else
        {
            $Report = ConvertTo-HTML -Body "$ComputerName $OSinfo $iscsitestouthtml $appdiscoveryhtml $applisthtml" -Title "SQL Onboarding Report"  -PostContent "<p>Report created: $(Get-Date)<p>"
        }

        #The command below will generate the report to an HTML file
        $Report | Out-File .\SQL-Onboarding-Report.html    
        write-host "Results output to: SQL-Onboarding-Report.html "
    }
}




##############################
#
#  M A I N    B O D Y
#
##############################


$hostVersionInfo = (get-host).Version.Major
if ($hostVersionInfo -lt 3)
{
    write-host "PowerShell version $hostVersionInfo is too downlevel.   Please upgrade to at least version 3.0"
    return
}


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
        $srcsql = $TRUE 
        $ToExec = $TRUE 
        $iscsitest = $FALSE}
    if ($userselection -eq 7) 
    {
        $srcsql = $TRUE  
        $tgtvdp = $TRUE  
        $ToExec = $TRUE 
        $iscsitest = $TRUE}
    if ($userselection -eq 8) {  Show-Usage  }


    
## Create an object based on the PSObject class
$thisObject = New-Object -TypeName psobject 

# first we get information
Get-SrcWin-Info
if ($true -eq $srcsql.IsPresent) {
  Get-WinObject-DiskInfo
  Get-SrcSql-Info $vdpip
}

# then we show information
Show-WinObject-Info
if ($true -eq $srcsql.IsPresent) 
{
    Show-WinObject-DiskInfo
    Show-SqlObject-Info $vdpip
}

# finally if the call to action is made, we make it
if ($true -eq $tgtvdp.IsPresent) 
{
    Get-TgtVDP-Info $ToExec.IsPresent
}
else 
{
    New-SQLHTMLReport    
}





exit
