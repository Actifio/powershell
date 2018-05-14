## Overview

This is a powershell script that will import all the direct-mount workflows from CSV file into an Actifo Appliance. The output in the form of SSV can be created manually or exported using export-wflow.ps1 script. Instead of a CSV (comma separated values) format, we will be using a SSV (semicolon separated values).You will need to specify an input file for each one of the application type: oracle, sqlserver and sqlinstance. 

### Setup
You will need to login to an Actifio appliance and run the command from the PowerShell prompt:

### Usage
To import the workflow definition from a SSV file, simply run:
```
./import-wflow.ps1 -ssvfile c:\temp\scripts\w_oracle.csv
```

To get help on the usage:
```
./export-wflow.ps1 -help
```

