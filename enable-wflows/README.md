## What does this do?

This is a powershell script that will enable a list of workflows on an Actifo Appliance.

## How does this work?

There are two files needed for this to work.
* _enable-wflows.ps1_  This file needs no configuration.  
* _actparams.ps1_  This is a parameter file that can be renamed.  Customise the values in the parameter file to your environment.
* _wflowlist.txt_ (optional) If you want to specify the list of workflows in a file instead of using the actparams.ps1 file.  You can list all the workflows in this file, separate each workflow name with a comma (,).

### Configuration of wflowlist.txt
Edit wflowlist.txt with the list of workflow names, comma separated, no double quotes.  Format should be like:
```
workflowname1,workflowname2,workflowname3
```

### Configuration of actparams.ps1
Edit actparams.ps1 with all parameters needed.  You can create multiple parameter files, just give each one a different name.

### Execute!
To run, simply use syntax like this:
```
./enable-wflows.ps1 -paramfile .\actparams.ps1
```
