## What does this do?

This is a powershell script that will login to a list of Actifo Appliances, run the same command on each one and then send a single email with the results using HTML format, so the output looks very readable.    You could automate this with a scheduler to get a regular email containing useful information.

## How does this work?

There are three files needed for this to work.
* _mail.ps1_  This file needs no configuration.  
* _config.ps1_  This is a config file that can be renamed.  You need one of these for every report you want.  If you use dfferent userids for each Appliance or group of Appliances, then you need one config file for each group.
* _appliancelist.txt_ This is a list of Appliances in a specific format.   You can create as many of these files as you want, using any file name you want.   This file is called by the config file.  If you have groups of appliances, such as a group in Australia and a group in the USA, you can create one file for each region.

### Configuration of appliancelist.txt
Edit appliancelist.txt with your appliances.   Do not add comments and make sure each appliance is separated from its IP address or FQDN with a comma.  Format should be like:
```
appliance1,172.1.1.1
appliance2,172.1.1.2
```
You can create multiple files like this and you reference the name of the appliance list in the config file.

### Configuration of config.ps1
Edit config.ps1 with all variables needed.  You can create multiple config files, just give each one a different name.

### Execute!
To run, simply use syntax like this:
```
./mail.ps1 -configfile .\config.ps1
```

