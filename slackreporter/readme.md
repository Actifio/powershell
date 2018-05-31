## What does this do?

This is a powershell script that will login to a list of Actifo Appliances, run the same command on each one and then send a post to Slack.    You could automate this with a scheduler to get a regular post containing useful information.

## How does this work?

There are three files needed for this to work.
* _act2slack.ps1_  This file needs no configuration.  
* slackparams.ps1_  This is a config file that can be renamed.  You need one of these for every report you want.  If you use dfferent userids for each Appliance or group of Appliances, then you need one config file for each group.
* _appliancelist.txt_ This is a list of Appliances in a specific format.   You can create as many of these files as you want, using any file name you want.   This file is called by the config file.  If you have groups of appliances, such as a group in Australia and a group in the USA, you can create one file for each region.

### Configuration of appliancelist.txt
Edit appliancelist.txt with your appliances.   Do not add comments and make sure each appliance is separated from its IP address or FQDN with a comma.  Format should be like:
```
appliance1,172.1.1.1
appliance2,172.1.1.2
```
You can create multiple files like this and you reference the name of the appliance list in the config file.

### Configuration of slackparams.ps1
Edit slackparams.ps1 with all variables needed.  You can create multiple config files, just give each one a different name.

### Execute!
To run, simply use syntax like this:
```
./_act2slack.ps1 -paramfile .\slackparams.ps1
```
Example output:

![alt text](https://github.com/Actifio/powershell/blob/master/slackreporter/images/screencap1.jpg)
