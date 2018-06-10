## Overview

This PowerShell script monitors a nominated job till either the job completes or the retry interval is exceeded.   
If the job completes or could not be found, an email will be sent.

## Usage

You should run the script using the following syntax (change job name to suit your own):
```
.\jobmonmailer.ps1 -paramfile .\actparams.ps1 -job Job_4938111
```

## Configuration

Configure the actparams.ps1 file to match your requirements.
Note that the mail server must support relay from the server where this PS1 script is run.
