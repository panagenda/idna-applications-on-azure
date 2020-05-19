#!/bin/bash
# This script is used to destroy the iDNA Applications infrastructure

set -e

az account set --subscription $subscriptionId

# customize those if needed
export rg="pana-ifa-tf-rg"

# get vault
export vaultName=$(az keyvault list --subscription=$subscriptionId -g $rg -o tsv | awk '{print $3}')

## extract and export secrets
export spSecret=$(az keyvault secret show --subscription=$subscriptionId --vault-name="$vaultName" --name sp-secret -o tsv | awk '{print $6}')
export spId=$(az keyvault secret show --subscription=$subscriptionId --vault-name="$vaultName" --name sp-id -o tsv | awk '{print $6}')
export saKey=$(az keyvault secret show --subscription=$subscriptionId --vault-name="$vaultName" --name sa-key -o tsv | awk '{print $6}')
export saName=$(az keyvault secret show --subscription=$subscriptionId --vault-name="$vaultName" --name sa-name -o tsv | awk '{print $6}')
export scName=$(az keyvault secret show --subscription=$subscriptionId --vault-name="$vaultName" --name sc-name -o tsv | awk '{print $6}')

# export secrets
export ARM_SUBSCRIPTION_ID=$subscriptionId
export ARM_TENANT_ID=$tenantId
export ARM_CLIENT_ID=$spId
export ARM_CLIENT_SECRET=$spSecret

# TF init
terraform init \
    -backend-config="access_key=$saKey" \
    -backend-config="storage_account_name=$saName" \
    -backend-config="container_name=$scName"

if test $? -ne 0; then
    echo "tf init finished with error..."
    exit
else
    echo "tf init done..."
fi

# destroy deployment
terraform destroy -auto-approve \
    -var "source_vhd_path=$template"

if test $? -ne 0; then
    echo "tf destroy finished with error..."
    exit
else
    echo "tf destroy done..."
fi

# delete sp
az ad sp delete --id $spId

# delete TF stuff
az group delete -y -n $rg

# delete local tf folder
rm -rf .terraform
