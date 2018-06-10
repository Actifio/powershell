# 
## File: jobmonmailer.ps1
## Purpose: monitors a job and then sends an email
## This script should not require any changes unless you want to change report formatting
#

param([string]$paramfile = $null , [string]$jobname = "$null")

if (! $paramfile) {
    write-host "You did not specify a paramater file which is needed for this script to work"
    write-host "Usage: .\jobmonmailer.ps1 -jobname <JobName> -paramfile [ full pathname of the parameter file ]"
    write-host "Example: .\jobmonmailer.ps1 -jobname Job_1234 -paramfile c:\actifio\actparams.ps1"
    break
}

if (! $jobname) {
    write-host "You did not specify a jobname"
    write-host "Usage: .\jobmonmailer.ps1 -jobname <JobName> -paramfile [ full pathname of the parameter file ]"
    write-host "Example: .\jobmonmailer.ps1 -jobname Job_1234 -paramfile c:\actifio\actparams.ps1"
    break
}

# Loads the parameter file in $paramfile
. $paramfile

if (!$keyfile) { $connectattempt=$(connect-Act -acthost $ApplianceIP -actuser $user -password $password -ignorecerts) }
if (!$password) { $connectattempt=$(Connect-Act -acthost $ApplianceIP -actuser $user -passwordfile $keyfile -ignorecerts) }

if ($connectattempt -ne "Login Successful!") {
	write-host "Failed to login to $ApplianceIP with username $user"
	exit
	}


$RetryCount = 1; $Completed = $false

while (-not $Completed) {
		$job_progress = $(udsinfo lsjob $jobname).progress
    if ($job_progress) {
    		 Start-Sleep $sleepinterval
        $RetryCount++

    if ($RetryCount -gt $MaxRetries) {
	Disconnect-Act -quiet
	exit
	}
    }
    else {
        $Completed = $true
    }
}

$mailbody = "<html> `n"
$mailbody += "<body> `n"
$mailbody += "<pre style=font: monospace> `n"

$job_check = $false
$job_check = $(udsinfo lsjobhistory $jobname).message
if ($job_check) {
		$job_history = $(udsinfo lsjobhistory $jobname)
		$job_status = $job_history.status
		$mailbody += "Full job details are below"
    		$mailbody += $job_history | out-string
    		Disconnect-Act -quiet
		}  else {
		$mailbody += "$(get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")   $jobname cannot be found as a running or completed job"
		$job_status = " could not be found"
		Disconnect-Act -quiet
}

$mailbody += "</pre> `n"
$mailbody += "</body> `n"
$mailbody += "</html> `n"

# subject line for the email
[string] $subject = "$jobname $job_status"

# we now mail out the file
Send-MailMessage -From $fromaddr -To $dest -Body $mailbody -SMTP $mailserver -subject $subject -BodyAsHtml 
