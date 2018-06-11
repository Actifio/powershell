## What does this do?

This is a powershell script that will send emails prior to unmounting and after mounting when a workflow is running

## How does this work?

There are two files needed for this to work.
* _mailnotifications.bat_  This file needs no configuration.  
* _mailnotifications.ps1_  This file has three settings that need to be changed.

Both files must be placed in C:\program files\actifio\scripts

### Configuration of mailnotifications.ps1
Edit mailnotifications.ps1 and change these three values to match your environment.
```
$mailserver = "smtp.acme.com"
$dest = "anthonyv@acme.com"
$fromaddr = "mgmt4@acme.com"
```

### Execute!
To use these simply specify  mailnotifications.bat in both the pre and post script fields of your workflow.  Fields should look like this:

![alt text](https://github.com/Actifio/powershell/blob/master/workflow_email_notifications/images/workflow_with_bat.jpg)

Emails will look like this:

![alt text](https://github.com/Actifio/powershell/blob/master/workflow_email_notifications/images/Email_notification.jpg)


