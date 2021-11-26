# blUser
## lock PC if no user nearby
### Install
### Configure
### Run
### Polybar Module
```ini
[module/bluser]
interval = 5
type = custom/script
exec = cat /tmp/bluser.log
click-left = ~/install/bluser/bluser.sh toggle
```
