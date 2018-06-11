### Can I specify a powershell (PS1) script in a workflow?

Actifio workflows allow you to specify a pre and post script.   For Windows these scripts need to be .CMD or .BAT (files that can be executed by a Windows Command Prompt).   

However these scripts can call PS1 scripts.  So a bat file could look like this:
```
cd /d "C:\Program Files\Actifio\scripts"

start /wait powershell -ExecutionPolicy Bypass "& .\postmountactions.ps1"
```
