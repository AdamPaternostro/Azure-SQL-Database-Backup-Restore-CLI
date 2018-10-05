# This script will export a database
# This assumes the BACPAC file does not exist (you must remove first)

################################
# Variables
################################
subscriptionId=00000000-0000-0000-0000-000000000000

sasToken='mygeneratedsastoken'
bacPacName=mybacpac.bacpac
containerName=bacpacs
storageAccountName=mystorageaccountname

sourceDatabaseServerName="myservername"
sourceDatabaseName="mydatabasename"
sourceResourceGroup="myresoucegroupname"
sourceDatabaseUsername="mydatabaseusername"
sourceDatabasePassword="mydatabasepassword"


################################
# Select the correct subscription
################################
# az login is not needed in the Azure Cloud Shell
# az login
az account set -s $subscriptionId


################################
# Export source
################################
az sql db export \
  -s $sourceDatabaseServerName \
  -n $sourceDatabaseName \
  -g $sourceResourceGroup \
  -u $sourceDatabaseUsername \
  -p $sourceDatabasePassword \
  --storage-key "?$sasToken" \
  --storage-key-type SharedAccessKey \
  --storage-uri "https://$storageAccountName.blob.core.windows.net/$containerName/$bacPacName"



