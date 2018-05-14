## Overview

This is a powershell script that will exports all the direct-mount workflows from an Actifo Appliance. The output in the form of SSV can then be imported using import-wflow.ps1 scripts. Three files will be automatically created: oracle.csv, sqlserver.csv and sqlinstance.csv . Instead of a csv format, we will be using a SSV (semicolon separated values).

### Setup
You will need to login to an Actifio appliance and run the command from the PowerShell prompt:

### Usage
To create the output file on c:\temp\scripts, simply run:
```
./export-wflow.ps1 -targetdir c:\temp\scripts
```

To get help on the usage:
```
./export-wflow.ps1 -help
```

To create the output file on c:\temp\scripts, prepend all the output file with w_ and prepend all the workflow name with v2:
```
./export-wflow.ps1 -targetdir c:\temp\scripts -pfx w -afx v2
```
