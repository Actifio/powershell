### Can I specify a powershell (PS1) script in a workflow?

Actifio workflows allow you to specify a pre and post script.   For Windows these scripts need to be in either .CMD or .BAT format and have relevant extension.   In other words, these have to be files that can be executed by a Windows Command Prompt.   

However these scripts can call PS1 scripts.  So if the postscript field specifies a bat file called postmount.bat which is located in  **C:\Program Files\Actifio\scripts**, it could could contain a script like this:
```
cd /d "C:\Program Files\Actifio\scripts"

start /wait powershell -ExecutionPolicy Bypass "& .\postmountactions.ps1"
```
You can find a working example here:   https://github.com/Actifio/powershell/tree/master/workflow_email_notifications
