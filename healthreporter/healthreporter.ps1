# 
## File: healthreporter.ps1
## Purpose: Emails output of reporthealth for a list of appliances
## This script should not require any changes unless you want to change email formatting
#

param([string]$paramfile = $null)

if (! $paramfile) {
    write-host "You did not specify a paramater file which is needed for this script to work"
    write-host "Usage: .\healthreporter.ps1 -paramfile [ full pathname of the parameter file ]"
    write-host "Example: .\healthreporter.ps1 -paramfile c:\actifio\actparams.ps1"
    break
}

# Loads the parameter file in $paramfile
. $paramfile

# ensure paramters used later are clean 
$cleanlist = ""
$badoutput = ""
[int]$total = 0
[int]$clean = 0

# learn current date to use in report
$currentdate = (get-date (get-date) -UFormat "%Y-%m-%d %H:%M:%S")

# turn appliance list into an array
$data = Import-Csv -Path $appliancelist -Header "ApplianceName","ApplianceIP" -Delimiter ","

# loop through appliance list array and issue reporthealth against each one
foreach ($item in $data){
  if (!$item.ApplianceIP) { 
    write-host "The appliancelist is not formatted correctly, there is a blank IP address"
    continue
  }
  if (!$keyfile) { Connect-Act -acthost $item.ApplianceIP -actuser $user -password $password -ignorecerts }
  if (!$password) { Connect-Act -acthost $item.ApplianceIP -actuser $user -passwordfile $keyfile -ignorecerts }
  $healthcheck = reporthealth -flnm | select  CheckName,Result,Status
  
  # a clean appliance has a single line in the reporthealth output.   If clean we add its name to the list and count it
  if (@($healthcheck).count -eq 1) { $cleanlist += $item.ApplianceName  
  $cleanlist += "`n"
  $clean = $clean +1 }
  
  # if the output of report health has more than 1 line we had a warning or failure so we need to print that output
  if (@($healthcheck).count -ne 1) { $badoutput += $healthcheck | out-string
  $badoutput += "`n"}
  
  # we total all appliances examined
  $total = $total +1
  disconnect-act
}

# we now start a mail body
$mailbody = "<html> `n"
$mailbody += "<body> `n"
$mailbody += "<pre style=font: monospace> `n"
$mailbody += "Report created on $currentdate `n"
$mailbody += "#################################### `n"
$mailbody += Write-Output "$total Appliances were checked and $clean Clean Appliances were found.  Appliances with messages are displayed below: `n"
if ($badoutput) { $mailbody += "-------------------------------------------------------------------------------- `n"
    $mailbody += $badoutput
}
$mailbody += "`n"
$mailbody += "-------------------------------------------------------------------------------- `n"
$mailbody += "The following Appliances were clean: `n"
$mailbody += $cleanlist
$mailbody += "`n"
$mailbody += "</pre> `n"
$mailbody += "</body> `n"
$mailbody += "</html> `n"
Send-MailMessage -From $fromaddr -To $dest -Body $mailbody -SMTP $mailserver -subject $subject -BodyAsHtml 

#  If email is not working, this shows the mail body
# $mailbody
