# 
## File: actparams.ps1
## Purpose: Sets the parameters required for the main PowerShell script
#

#  This is the user we will connect to the Appliance with.   
[string] $acthost = "172.24.16.192"

#  This is the user we will connect to the Appliance with.   
[string] $actuser = "admin"

# we need to choose only one access method.  Use a hash to block out the one you dont use.   
[string] $actpassword = "password"
# [string] $actpasswordfile = "c:\actifio\$env:USERNAME-passwd.key"

# List of workflows either in $wflowlist or in the $wflowlistFile file. Use either one of the following:
#
[string] $wflowlist = "workflow_test,vstar"

# Content of $wflowlistFile should be of the format as follow:  
# workflow_test,vstar
[string] $wflowlistFile = "./wflowlist.txt"


