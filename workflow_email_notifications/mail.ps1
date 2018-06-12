# 
## File: workflowmailer.ps1
## Purpose: sends an email while a workflow is running

param([string]$destemail = $null,[string]$mailserver = $null,[string]$fromaddr = $null)

#  This is here in case we need to log
# $VerbosePreference = "Continue"
# $LogPath = "C:\program files\actifio\scripts\ps.log"
# Start-Transcript $LogPath -Append

# these parms are all supplied
# $mailserver = "smtp.acme.com"
# $dest = "anthonyv@acme.com"
# $fromaddr = "mgmt4@acme.com"


# Write-Verbose "$(Get-Date): We test parms."

if (! $destemail) {
    exit
}
if (! $mailserver) {
    exit
}
if (! $fromaddr) {
    exit
}

# Write-Verbose "$(Get-Date): We test for logsmart."

# if this is a log smart mount or unmount dont report it
if (Test-Path Env:ACT_LOGSMART_TYPE) { 
	if  ($(Get-Item Env:ACT_LOGSMART_TYPE).Value -eq "log" ) {
		exit
	}
}

function Sendmail{
$mailbody = "<html> `n"
$mailbody += "<body> `n"
$mailbody += "<pre style=font: monospace> `n"
$mailbody += "Workflow job: $jobtype `n"
$mailbody += "Jobname: $jobname `n"
$mailbody += "SourceHost: $sourcehost `n"
$mailbody += "Appname: $appname `n"
if ($dbname) { $mailbody += "DBName: $dbname `n" }
$mailbody += "AppID: $appid `n"
$mailbody += "TargetHost: $targethost `n"
$mailbody += "</pre> `n"
$mailbody += "</body> `n"
$mailbody += "</html> `n"
# we now mail out the file
Send-MailMessage -From $fromaddr -To $destemail -Body $mailbody -SMTP $mailserver -subject $subject -BodyAsHtml 
}

$jobname = $(Get-Item Env:ACT_JOBNAME).Value
$jobtype = $(Get-Item Env:ACT_JOBTYPE).Value
$sourcehost = $(Get-Item Env:ACT_SOURCEHOST).Value
$appname = $mailbody += $(Get-Item Env:ACT_APPNAME).Value
$appid = $(Get-Item Env:ACT_APPID).Value
$targethost = $(Get-Item Env:COMPUTERNAME).Value
if (Test-Path Env:dbname) { $dbname = $(Get-Item Env:dbname).Value }

# if this is an unmount in pre phase report it
if (( $(Get-Item Env:ACT_MULTI_OPNAME).Value -eq "unmount" ) -and ( $(Get-Item Env:ACT_PHASE).Value -eq "pre" )) {
	[string] $subject = "Unmount $jobname is being run by workflow on $targethost"
	Sendmail
}

# if this is an mount in post phase report it
if (( $(Get-Item Env:ACT_MULTI_OPNAME).Value -eq "mount" ) -and ( $(Get-Item Env:ACT_PHASE).Value -eq "post" )) {
	[string] $subject = "Mount $jobname was run by workflow on $targethost"
	Sendmail
}


# Stop-Transcript
