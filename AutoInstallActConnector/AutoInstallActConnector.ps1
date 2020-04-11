# 
## File: AutoInstallActConnector.ps1
## Purpose: Script to automate the installation of Actifio connector on a Windows server.
#
# Version 1.0 Initial Release
#

<#   
.SYNOPSIS   
   Download and install Actifio connector on a Windows host.
.DESCRIPTION 
   This is a powershell script that helps you auomate the process of installing Actifio connector modules from the VDP appliance. It can automate the download and installation process. It allows users to deploy the Actifio connector with Filter Driver enabled or disabled. Since this can be run from command line, you can integrate with any third-party application deployment software or Microsoft Active Directory.
.PARAMETER VdpIp
    IP address of the VDP appliance
.PARAMETER Install
    To install the connector software.
.PARAMETER Download
    To download the connector software from VDP appliance.
.PARAMETER Cbt
    To install the connector with filter driver / CBT enabled.
.PARAMETER TmpDir
    Location of the temporary directoru
.PARAMETER SwFile
    Name of the connector software executable file.        
.EXAMPLE
    PS > .\AutoInstallActConnector.ps1 -download -install -Cbt

    To download and install the Actifio connector software. It will used the default temporary directory.
.EXAMPLE
    PS > .\AutoInstallActConnector.ps1 -download -VdpIp 10.10.10.1 -TmpDir c:\temp

    To download the Actifio connector software from VDP appliance (10.10.10.1) 
.EXAMPLE 
    PS > .\AutoInstallActConnector.ps1 -install -TmpDir c:\temp -SwFile connector.exe -Cbt

    To install the Actifio connector software c:\temp\connector.exe with CBT enabled.
.NOTES   
    Name: AutoInstallActConnector.ps1
    Author: Michael Chew
    DateCreated: 6-April-2020
    LastUpdated: 11-April-2020
.LINK
    https://github.com/Actifio/powershell/blob/master/AutoInstallActConnector   
#>

[CmdletBinding()]
Param
( 
  [switch]$Download = $false,         # To download the software
  [switch]$Install = $false,          # To install the software
  [switch]$Cbt = $true,               # To install the Actifio software with CBT enabled
  [string]$VdpIp = "",                # IP address of the VDP appliance
  [string]$TmpDir = "",               # Location of the directory of the zip file
  [string]$SwFile = ""                # Location of the directory of the zip file
)  ### Param

$ScriptVersion = "1.0"
$Version = "9.0"

##################################
# Function: Download-Actifio-Connector
#
# Download the Actifio connector from VDP IP appliance
# 
##################################
function Get-Actifio-Connector (
      [string]$Version,
      [string]$VdpIp,
      [string]$TmpDir )
{
  Write-Host "I will be downloading Actifio connector version $Version. "

  if ($null -eq $VdpIP -or "" -eq $VdpIP) {
    $VdpIp = Read-Host -Prompt 'Please enter the VDP IP address '
  }

  if ( Test-Connection $VdpIp -Count 2 -Quiet ) {

    $software = "connector-Win32-latestversion.exe"
    # Download the Actifio connector software fromt the Actifio appliance
    $url = "http://$VdpIp/$software"

    $download_path = "$TmpDir\$software"
    
    ## Change the security protocol to use TLSv1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host "Downloading latest version of Actifio connector from $url" -ForegroundColor Cyan

    # Check if Invoke-Webrequest exists otherwise execute WebClient
    if (Get-Command 'Invoke-Webrequest') {
      Invoke-WebRequest -Uri $url -OutFile $download_path
    } else {
      $WebClient = New-Object System.Net.WebClient
      $webclient.DownloadFile($url, $download_path)
    }

    Write-Host "Actifio connector saved to $download_path" -ForegroundColor Green
    return $software

  } else {
    Write-Host "Unable to ping $VdpIp . Please verify the IP address of the VDP appliance. "
    return $Null
  }
}

##################################
# Function: Install-Actifio-Connector
#
##################################
function Install-Actifio-Connector ( 
  [string]$Version,
  [bool]$IsCbt,
  [string]$TmpDir,
  [string]$Software )
{
  Write-Host "I will be installing Actifio connector version $Version . "

#
# Location of the Actifio connector modules
#

  if ( Test-Path "$TmpDir\$Software" ) {
    # Kick off the installation of the Actifio connector
    Write-Host "Beginning installing Actifio connector" -ForegroundColor Cyan

    if ( $IsCbt ) {
      # /type=full is to install the Filter Driver
      Start-Process -FilePath "$TmpDir\$Software" -ArgumentList "/silent /type=full " -verb RunAs
    } else {
      # /type=compact is to not install the Filter Driver
      Start-Process -FilePath "$TmpDir\$Software" -ArgumentList "/silent /type=compact " -verb RunAs
    }

  } else {
    Write-Host "Unable to locate $TmpDir\$Software, installation failed. Please verify the location and the name of the software . "

  }

}

##################################
# Function: Show-Usage
#
##################################
function Show-Usage ()
{
  write-host "Usage: .\AutoInstallActConnector.ps1 [ -Download -Install | -Download | -Install ] [ -TmpDir <directory name> ] [ -SwFile <connector software> ] [ -VdpIp <Vdp Ip> ] [ -Cbt ] `n"
  write-host " get-help .\AutoInstallActConnector.ps1 -examples"
  write-host " get-help .\AutoInstallActConnector.ps1 -detailed"
  write-host " get-help .\AutoInstallActConnector.ps1 -full"    
}     ### end of function

##############################
#
#  M A I N    B O D Y
#
##############################

if ($Download -eq $false -And $Install -eq $false) {
  Show-Usage
  exit
}

if ($null -eq $TmpDir -And "" -eq $TmpDir) {
  $TmpDir = $($env:TEMP)
  }

write-host "Temporary Directory = $TmpDir"

if ( $Download ) {
  $SwFile = Get-Actifio-Connector $Version $VdpIp $TmpDir
}

if ( $Install ) {
  if ($Null -ne $SwFile -And "" -ne $SwFile) {
    Install-Actifio-Connector $Version $Cbt.IsPresent $TmpDir $SwFile
  }
}

exit