# azure-s2s-template

This a companion guide to the blog post [Build a DevTest Azure Site-to-Site VPN on a Linux VM](https://blog.notnot.ninja/2020/09/12/azure-site-to-site-vpn/)

![ARM template diagram](ARM-template.png?raw=true "ARM template")


## Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2fphilipf%2fazure-s2s-template%2fmaster%2ftemplate.json){:target="_blank"}


## Install Libreswan on a clean Ubuntu 20.04

Install with `wget`

```bash
sudo sh -c "$(wget -qO- https://raw.githubusercontent.com/philipf/azure-s2s-template/master/install.sh)"
```

or install with `curl`

```bash
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/philipf/azure-s2s-template/master/install.sh)"
```
