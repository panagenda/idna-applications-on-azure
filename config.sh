#!/bin/bash
# This script can be used to configure an iDNA Applications appliance
# Example: ./config.sh "my-ifa.my-domain.com" "Europe/Berlin" "my-root-password"

set -e

# exports secrets if available; export manually otherwise
if [ -f "./creds.sh" ]; then
    source ./creds.sh
fi

# get input
if [[ -z $1 || -z $2 || -z $3 ]]; then
    echo "usage: ./creds.sh <hostname> <timezone> <root-password>"
    exit
fi

export test=$(echo -n $3 | wc -c)
if test $test -lt "8"; then
    echo "Please provide at least 8 chars as secret value."
    exit
fi

export hostname=$1
export timezone=$2
export rootPsw=$3

# get ip
export ip=$(terraform output | grep public_ip_address | awk '{print $3}')
export rg=$(terraform output | grep resource_group | awk '{print $3}')
export location=$(terraform output | grep location | awk '{print $3}')
export prefix=$(terraform output | grep prefix | awk '{print $3}')
export secGroup=$prefix-secgroup

configureAppliance() {
    #configure appliance
    echo "In a few seconds you will be prompted for the root password"
    ssh -o "StrictHostKeyChecking no" root@$ip "echo $hostname >> /etc/hostname && \
   hostnamectl set-hostname $hostname && \
   timedatectl set-timezone $timezone && \
   echo $rootPsw | passwd --stdin root"

    if test $? -ne 0; then
        echo "unable to configure appliance..."
        # no exit
    else
        echo "appliance configured..."
    fi
}

configureAccess() {
    # get public ip
    export mypublicIp=$(dig +short myip.opendns.com @resolver1.opendns.com.)

    # create network policy inbound rule
    az network nsg rule create -g $rg --nsg-name $secGroup -n ifa-config --priority 200 \
        --source-address-prefixes $mypublicIp --source-port-ranges "*" \
        --destination-address-prefixes '10.0.0.0/16' --destination-port-ranges 22 --access Allow \
        --protocol Tcp

    if test $? -ne 0; then
        echo "unable to create security policy..."
        exit
    else
        echo "security policy created..."
    fi
}

removeAccess() {
    # delete network rule
    az network nsg rule delete -g $rg --nsg-name $secGroup -n ifa-config

    if test $? -ne 0; then
        echo "unable to delete the security policy..."
        exit
    else
        echo "security policy deleted..."
    fi
}

# get network policy groups
export nsg=$(az network nsg list --resource-group $rg --subscription $subscriptionId | grep -i $secGroup | wc -l | awk '{print $1}')
if test $nsg -ge 1; then
    configureAccess
fi

configureAppliance

if test $nsg -ge 1; then
    removeAccess
fi
