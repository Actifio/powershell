# 
## File: jobmonitor.ps1
## Purpose: monitors a job
## This script should not require any changes unless you want to change report formatting
#

param([string]$paramfile = $null , [string]$jobname = "$null")

if (! $paramfile) {
    write-host "You did not specify a paramater file which is needed for this script to work"
    write-host "Usage: .\jobmonitor.ps1 -jobname <JobName> -paramfile [ full pathname of the parameter file ]"
    write-host "Example: .\jobmonitor.ps1 -jobname Job_1234 -paramfile c:\actifio\actparams.ps1"
    break
}

if (! $jobname) {
  write-host "You did not specify a jobname"
  write-host "Usage: .\jobmonitor.ps1 -jobname <JobName> -paramfile [ full pathname of the parameter file ]"
  write-host "Example: .\jobmonitor.ps1 -jobname Job_1234 -paramfile c:\actifio\actparams.ps1"
  break
}

# Loads the parameter file in $paramfile
. $paramfile

if (!$keyfile) { 
  $connectattempt=$(connect-Act -acthost $ApplianceIP -actuser $user -password $password -ignorecerts) 
}
if (!$password) { 
  $connectattempt=$(Connect-Act -acthost $ApplianceIP -actuser $user -passwordfile $keyfile -ignorecerts) 
}

if ($connectattempt -ne "Login Successful!") {
  write-host "Failed to login to $ApplianceIP with username $user"
  exit
}

$RetryCount = 1; $Completed = $false

while (-not $Completed) {
  $job_progress = $(udsinfo lsjob $jobname).progress
  if ($job_progress) {
    $timenow = $(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")
    Write-host  "$timenow   $jobname is at $job_progress%   This is check $RetryCount of $MaxRetries (with $sleepinterval second intervals)"
    Start-Sleep $sleepinterval
    $RetryCount++

    if ($RetryCount -gt $MaxRetries) {
	    Write-host "$(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")   Stopped monitoring after $MaxRetries checks"
	    Disconnect-Act -quiet
	    exit
    }
  }
  else {
    $Completed = $true
  }
}


$job_check = $false
$job_check = $(udsinfo lsjobhistory $jobname).message
if ($job_check) {
	$job_history = $(udsinfo lsjobhistory $jobname)
	$job_message = $job_history.message
	$job_start = $job_history.startdate
	$job_end = $job_history.enddate
	$ts = [datetime]$job_end -[datetime]$job_start
	$timestamp = $(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")
    	[console]::WriteLine("$timestamp   $jobname ended after this duration (hh:mm:ss.ff): {0:g}", $ts)
    	write-host "$timestamp   $jobname ended with this message: $job_message"
    	Disconnect-Act -quiet
    	}  else {
	write-host "$(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")   $jobname cannot be found as a running or completed job"
	Disconnect-Act -quiet
}
