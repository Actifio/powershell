# 
## File: unmounteverything.ps1
## Purpose: Unmounts all mounts on an appliance
#

param([string]$paramfile = $null)

if (! $paramfile) {
    write-host "Usage: .\unmounteverything.ps1 -paramfile [ full pathname of the parameter file ]"
    write-host "Example: .\unmounteverything.ps1 -paramfile c:\actifio\actparams.ps1"
    break
}

# Loads the parameter file in $paramfile
. $paramfile

# Ensure that the ActPowerCLI module is imported
$moduleins = get-module -listavailable -name ActPowerCLI
if ($moduleins -eq $null) {
    Import-Module ActPowerCLI
}

# Connect to the Actifio appliance
#
# Are we using passwordfile to authenticate to the Actifio appliance ?
if (!$keyfile) { 
    $connectattempt=$(connect-Act -acthost $ApplianceIP -actuser $user -password $password -ignorecerts) 
  }
  if (!$password) { 
    $connectattempt=$(Connect-Act -acthost $ApplianceIP -actuser $user -passwordfile $keyfile -ignorecerts) 
  }
  
  if ($connectattempt -ne "Login Successful!") {
    write-host "(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")  Failed to login to $ApplianceIP with username $user"
    exit }
    else {
        Write-host "$(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")  Logged into $ApplianceIP with username $user"
  }

# learn the current mounts
$mounts = $(udsinfo lsbackup -filtervalue characteristic=mount).backupname

# test for mounts
if ($mounts -eq $null) {
    Write-host "$(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")  There are no mounts."
    exit
}

#  alert
$count=($mounts | Measure-Object).count
Write-host "$(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")  There are $count mounts.  They are: $mounts"
Write-host "$(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")  Unmounting them now:"

# unmount all mounts
foreach ($image in $mounts) {
    udstask unmountimage -image $image -nowait
}
# waiting for jobs to kickoff
sleep 10

# wait for completion
$RetryCount = 1; $Completed = $false
while (-not $Completed) {
    $unmountjobs = $(udsinfo lsjob -filtervalue jobclass=unmount).progress
    if ($unmountjobs) {
      $count=($unmountjobs | Measure-Object).count
      Write-host  "$(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")  Found $count running unmounts, progress%: $unmountjobs   Check $RetryCount of $MaxRetries ($sleepinterval second intervals)"
      Start-Sleep $sleepinterval
      $RetryCount++
  
      if ($RetryCount -gt $MaxRetries) {
          Write-host "$(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")  Stopped monitoring after $MaxRetries checks"
          Disconnect-Act -quiet
          exit
      }
    }
    else {
      $Completed = $true
    }
  }

# learn the current mounts
$mounts = $(udsinfo lsbackup -filtervalue characteristic=mount).backupname

# test for mounts
if ($mounts -eq $null) {
    Write-host "$(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")  There are no mounts.  We are complete" }
    else {
    Write-host "$(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")  There are still mounts.  Please investigate failed unmount jobs or re-run this script."
}

$logout = $(Disconnect-Act -quiet)
exit
