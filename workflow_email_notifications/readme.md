## What does this do?

This is a powershell script that will send emails prior to unmounting and after mounting when a workflow is running

## How does this work?

There are two files needed for this to work.
* _mail.bat_  This file needs no configuration.  
* _mail.ps1_  This file needs no configuration.  

Both files must be placed in C:\program files\actifio\scripts

### Execute!
To use these simply specify  mail.bat in ether the pre and post script fields of your workflow or both and then three parms as shown.  Fields should look like this.
```
mail.bat <destination email address> <mail server> <from email address>
```
For instance:
```
mail.bat anthonyv@acme.com smtp.acme.com mgmt4@acme.com
```
This will send an email to anthonyv@acme.com using mail server smtp.acme.com with a from address of mgmt4@acme.com.

![alt text](https://github.com/Actifio/powershell/blob/master/workflow_email_notifications/images/Workflow_three_parm.jpg)

Emails will look like this:

![alt text](https://github.com/Actifio/powershell/blob/master/workflow_email_notifications/images/Email_notification.jpg)


