# 
## File: workflowmailer.ps1
## Purpose: sends an email while a workflow is running

# these three values need to match your environment.
$mailserver = "smtp.acme.com"
$dest = "anthonyv@acme.com"
$fromaddr = "mgmt4@acme.com"


#  You shouldn't need to customize from here down:
function Sendmail{
$mailbody = "<html> `n"
$mailbody += "<body> `n"
$mailbody += "<pre style=font: monospace> `n"
$mailbody += " Workflow job: "
$mailbody += $(Get-Item Env:ACT_JOBTYPE).Value
$mailbody += "`n Jobname: "
$mailbody += $(Get-Item Env:ACT_JOBNAME).Value
$mailbody += "`n SourceHost: "
$mailbody += $(Get-Item Env:ACT_SOURCEHOST).Value
$mailbody += "`n Appname: "
$mailbody += $(Get-Item Env:ACT_APPNAME).Value
$mailbody += "`n AppID: "
$mailbody += $(Get-Item Env:ACT_APPID).Value
$mailbody += "`n TargetHost: "
$mailbody += $(Get-Item Env:COMPUTERNAME).Value
$mailbody += "</pre> `n"
$mailbody += "</body> `n"
$mailbody += "</html> `n"
# we now mail out the file
Send-MailMessage -From $fromaddr -To $dest -Body $mailbody -SMTP $mailserver -subject $subject -BodyAsHtml 
}

if (( $(Get-Item Env:ACT_MULTI_OPNAME).Value -eq "unmount" ) -and ( $(Get-Item Env:ACT_PHASE).Value -eq "pre" )) {
[string] $subject = "Unmount is being run by workflow"
Sendmail
}

if (( $(Get-Item Env:ACT_MULTI_OPNAME).Value -eq "mount" ) -and ( $(Get-Item Env:ACT_PHASE).Value -eq "post" )) {
[string] $subject = "Mount was run by workflow"
Sendmail
}
