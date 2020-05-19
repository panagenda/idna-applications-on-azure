#!/bin/bash

# Run this script to configure all everything to use Terraform

set -e

az account set --subscription $subscriptionId

# customize those if needed
export rg="pana-ifa-tf-rg"
export location="westeurope"
export sku="Standard_LRS"
export vaultName="ifavault$RANDOM$RANDOM"
export saName="panaifasa$RANDOM$RANDOM"
export scName="panaifasc$RANDOM$RANDOM"
export spName="http://pana-ifa-sp-$RANDOM$RANDOM"

# creates a new resource group which will be used for the vault and TF state
az group create --name "$rg" \
    --location "$location" \
    --subscription="$subscriptionId"

if test $? -ne 0; then
    echo "resource group couldn't be created..."
    exit
else
    echo "resource group created..."
fi

# creates a vault to store secrets
az keyvault create --name "$vaultName" \
    --resource-group $rg \
    --location "$location" \
    --subscription=$subscriptionId \
    --enable-soft-delete true

if test $? -ne 0; then
    echo "vault couldn't be created..."
    exit
else
    echo "vault created..."
fi

# creates storage account used by TF
az storage account create --resource-group $rg \
    --name $saName \
    --sku $sku \
    --encryption-services blob \
    --subscription=$subscriptionId

if test $? -ne 0; then
    echo "storage account couldn't be created..."
    exit
else
    echo "storage account created..."
fi

# gets storage account key
export accountKey=$(az storage account keys list --subscription=$subscriptionId --resource-group $rg --account-name $saName --query [0].value -o tsv)

# creats storage container used by TF
az storage container create --name $scName --account-name $saName --account-key $accountKey

if test $? -ne 0; then
    echo "storage container couldn't be created..."
    exit
else
    echo "storage container created..."
fi

# saves secrets to vault
az keyvault secret set --vault-name $vaultName \
    --name "sa-key" \
    --value "$accountKey"
az keyvault secret set --vault-name $vaultName \
    --name "sa-name" \
    --value "$saName"
az keyvault secret set --vault-name $vaultName \
    --name "sc-name" \
    --value "$scName"

if test $? -ne 0; then
    echo "secrets couldn't be saved..."
    exit
else
    echo "secrets are saved in vault..."
fi

# creates a service principal
export sp=$(az ad sp create-for-rbac --name $spName --years 99 --role="Contributor" --scopes="/subscriptions/$subscriptionId" -o tsv)

if test $? -ne 0; then
    echo "service principal couldn't be created..."
    exit
else
    echo "service principal created..."
fi
# gets id and secret
export spSecret=$(echo $sp | awk '{print $4}')
export spId=$(echo $sp | awk '{print $1}')

# save secrets to vault
az keyvault secret set --vault-name $vaultName \
    --name "sp-id" \
    --value "$spId"
az keyvault secret set --vault-name $vaultName \
    --name "sp-secret" \
    --value "$spSecret"

if test $? -ne 0; then
    echo "secrets couldn't be saved..."
    exit
else
    echo "secrets are saved in vault..."
fi
