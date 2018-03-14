#  This is the user we will connect to the Applance with.   
[string] $user = "admin"

# we need to choose only one access method.  Use a hash to block out the one you dont use.   
[string] $password = "passw0rd"
# [string] $passwordfile = "./keyfile.key"

#  this variable defines a second file where we store the names of the appliances we are going to interact with
# The file needs to contain one line for each appliance in the format:    appliancename,applianceip
[string] $appliancelist = "./appliancelist.txt"

# Destination addresses.  Make sure to add extra addrs with the same format
$dest = "anthonyv@acme.com","aarontully@acme.com"
# from address for the email
[string] $fromaddr = "actifioreporter@acme.com"
# subject line for the email
[string] $subject = "Daily ReportHealth"
# mail server that will hopefully relay our mail
[string] $mailserver = "smtp.acme.com"
