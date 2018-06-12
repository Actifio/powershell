cd /d "C:\Program Files\Actifio\scripts"
start /wait powershell -ExecutionPolicy Bypass "& .\mail.ps1 -destemail %2 -mailserver %3 -fromaddr %4"


