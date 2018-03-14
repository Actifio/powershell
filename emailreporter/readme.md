### Configuration of appliancelist.txt
Edit appliancelist.txt with your appliances.   Do not add comments and make sure each appliance is separated from its IP address or FQDN with a comma.  Format should be like:
```
appliance1,172.1.1.1
appliance2,172.1.1.2
```
You can create multiple files like this and reference them in the config file.

### Configuration of config.ps1
Edit config.ps1 with all variables needed.  You can create multiple config files, just give each one a different name.

### Execute!
To run, simply use syntax like this:
```
./mail.ps1 -configfile .\config.ps1
```

