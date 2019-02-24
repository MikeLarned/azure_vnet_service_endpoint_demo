### SSH

```
ssh adminuser@13.66.154.104
5UqCM3JQf3t4UCtK
putty.exe azureuser@13.66.154.104 -pw 5UqCM3JQf3t4UCtK
```

```
z vm user update --resource-group rg-endpoints-demo-wu2 --name app-endpoints-demo-wu2 --username azureuser \
  --password myNewPassword
```

```
source <(curl -s http://mywebsite.com/myscript.txt)
```