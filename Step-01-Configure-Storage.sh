# This script will create a blob container for storing BACPACs
# The script will also generate a SAS token to the container so the export/import processes use a SAS token
# NOTE: You should change the expiration length of the SAS token
# Typically an Azure "admin" would run this script and provide the SAS token to for use in Steps 02 and 03

################################
# Variables
################################
subscriptionId=00000000-0000-0000-0000-000000000000

containerName=bacpacs
storageAccountName=mystorageaccountname
storageAccountKey=mystoragekey


################################
# Select the correct subscription
################################
# az login is not needed in the Azure Cloud Shell
# az login
az account set -s $subscriptionId


################################
# Create the blob container and generate a SAS token
# This step only needs to be done once
################################
az storage container create \
  --name $containerName \
  --account-key $storageAccountKey \
  --account-name $storageAccountName \
  --public-access off

az storage container generate-sas \
  --name $containerName \
  --account-key $storageAccountKey \
  --account-name $storageAccountName \
  --start  2018-01-01T00:00:00Z \
  --expiry 2020-01-01T00:00:00Z \
  --https-only \
  --permissions rwl

# Take the generated SAS token and place in the Step-02-Backup-and-Restore.sh and Step-02-Backup-Database.sh script