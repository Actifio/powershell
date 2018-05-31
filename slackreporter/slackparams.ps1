# 
## File: actparams.ps1
## Purpose: Sets the parameters required for the main PowerShell script
#

#  This is the user we will connect to the Applance with.   
[string] $user = "admin"

# we need to choose only one access method.  Use a hash to block out the one you dont use
# Manually enter plaintext password
 [string] $password = "password"
# unhash this line and set path to the password file
# [string] $keyfile = "./keyfile.key"

#  this variable defines a second file where we store the names of the appliances we are going to interact with
# The file needs to contain one line for each appliance in the format:    appliancename,applianceip
[string] $appliancelist = "./appliancelist.txt"

#  this variable is the command we will run on the Actifio Appliance.  The command needs to be in double quotes
#  You may need to use different quoting if double quotes are needed inside the select, such as:   
#  $command = 'reportapps -gc | select apptype,appname,"mdlstat(gb)","total(gb)","postcompress(gb)","organizations"'
   [string]  $command = 'reportrpo | where {$_.Apptype -eq "VMBackup"} | select appname, snapshotdate'
#  [string]  $command = "reportrpo | select appname, snapshotdate"
# [string] $command = "reportsnaps -d1 | select startdate,hostname,appname,capturetype"

# reportname - change to match what you ran
$reportname = "reportrpo"


# SlackVariabls
# Hook URL - you will need your own
$Url = "https://hooks.slack.com/services/789/456/123"

# username that will post to slack
$Username = "Actifio Bot"

# channel that we wll post to slack
$Channel = "#testme" 

#  emoji to use
# $Emoji = ":amazon:" 

#  Icon to use
# $IconUrl =

