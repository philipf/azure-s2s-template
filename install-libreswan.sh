#!/bin/sh
#
# Installs and configures Libreswan to connect an Azure VPN Gateway.
# See: https://blog.notnot.ninja/2020/09/12/azure-site-to-site-vpn/
#
# This script should be run via curl:
#   sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/philipf/azure-s2s-template/master/install-libreswan.sh)"
# or via wget:
#   sudo sh -c "$(wget -qO- https://raw.githubusercontent.com/philipf/azure-s2s-template/master/install-libreswan.sh)"
# or via fetch:
#   sudo sh -c "$(fetch -o - https://raw.githubusercontent.com/philipf/azure-s2s-template/master/install-libreswan.sh)"
#
# As an alternative, you can first download the install script and run it afterwards:
#   wget https://raw.githubusercontent.com/philipf/azure-s2s-template/master/install.sh
#   sudo sh install.sh
#

set -e

main() {
    echo 'Install Libreswan for an Azure site-to-site VPN'
    echo 'For more details: https://blog.notnot.ninja/2020/09/12/azure-site-to-site-vpn/'

    read -p 'Virtual Gateway IP (VIP): ' vgw_vip
    read -p 'Azure VNet [192.168.3.0/24]: ' left_subnet
    left_subnet=${left_subnet:-192.168.3.0/24}

    read -p 'Local network [192.168.1.0/24]: ' right_subnet
    right_subnet=${right_subnet:-192.168.1.0/24}

    read -p 'Pre-shared key: ' psk # <1>
    
    apt update

    # Install the build dependencies for Libreswan
    apt install -y \
        libnss3-dev \
        libnspr4-dev \
        pkg-config \
        libpam-dev \
        libcap-ng-dev \
        libcap-ng-utils \
        libselinux-dev \
        libcurl3-nss-dev \
        flex \
        bison \
        gcc \
        make \
        libldns-dev \
        libunbound-dev \
        libnss3-tools \
        libevent-dev \
        xmlto \
        libsystemd-dev \
        gawk 

    # Install wget to download Libreswan source
    apt install -y wget

    wget https://github.com/libreswan/libreswan/archive/v3.32.tar.gz

    tar -xzvf v3.32.tar.gz
    cd libreswan-3.32/

    # Include the deprecated Diffie-Hellman group 2 (modp1024) as required by Azure's Basic SKU
    export USE_DH2=true # <2>
    export USE_FIPSCHECK=false # <3>
    export USE_DNSSEC=false # <3>   

    make clean
    make base
    make install-base

# Create the connection definition to Azure
cat <<END > /etc/ipsec.d/azure.conf
conn azureTunnel
    authby=secret
    auto=start
    dpdaction=restart
    dpddelay=30
    dpdtimeout=120
    ike=aes256-sha1;modp1024
    ikelifetime=3600s
    ikev2=yes
    keyingtries=3
    pfs=yes
    phase2alg=aes128-sha1
    left=$vgw_vip
    leftsubnets=$left_subnet
    right=%defaultroute
    rightsubnets=$right_subnet
    salifetime=3600s
    type=tunnel
END

# Create secrets file with a pre-shared key
cat <<END > /etc/ipsec.d/azure.secrets
%any %any : PSK "$psk"
END

    # Enable and start the IPsec service
    systemctl enable ipsec.service
    systemctl start ipsec.service
    systemctl status ipsec.service

    printf "Completed successfully\n"
}

main 