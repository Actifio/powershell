
## What does this do?

This is a powershell script that will disable a list of workflows in an Actifo Appliance.

## How does this work?

There are two files needed for this to work.
* disable-wflows.ps1_  This file needs no configuration.  
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
./disable-wflows.ps1 -paramfile .\actparams.ps1
```

### Sample Output:
```
./disable-wflows.ps1 .\actparams.ps1                                                                                                                 
Connected to 172.24.16.192
Disabling workflow id ( 315394 ) for workflow_test
udstask chworkflow -disable true 315394
Disabling workflow id ( 306666 ) for vstar
udstask chworkflow -disable true 306666
Success!
```
