# This script will restore a single database
# In order to import the database, the destination database must be empty. 
# This script will delete the current database, create a new empty one with the same name, then import (you should the service objective below "S0")
# This assumes the BACPAC file does not exist (you must remove first)

################################
# Variables
################################
sasToken='mygeneratedsastoken'
bacPacName=mydatabasename.bacpac
containerName=bacpacs
storageAccountName=mystorageaccountname

destinationSubscriptionId="00000000-0000-0000-0000-000000000000"
destinationDatabaseServerName="myservername"
destinationDatabaseName="mydatabasename"
destinationResourceGroup="myresoucegroupname"
destinationDatabaseUsername="mydatabaseusername"
destinationDatabasePassword="mydatabasepassword"

################################
# Select the correct subscription
################################
# az login is not needed in the Azure Cloud Shell
# az login
az account set -s $destinationSubscriptionId


################################
# Delete the existing database
# Create a new one (same name)
# Import database
################################
# jq variables
databaseNameToTest=$destinationDatabaseName
databaseNameToTest="$databaseNameToTest" jq -n 'env.databaseNameToTest'

# Test to see if the database exists
databaseList=$(az sql db list --resource-group $destinationResourceGroup --server $destinationDatabaseServerName  --query '[].name')
doesDatabaseExist=$(echo $databaseList |jq -r --arg databaseNameToTest "$databaseNameToTest" 'index($databaseNameToTest)')

if [ $doesDatabaseExist = "null" ]; then
    echo "Database does not exist: $destinationDatabaseName"
else   
    echo "Deleting database: $destinationDatabaseName"
    az sql db delete -y \
        -s $destinationDatabaseServerName \
        -n $destinationDatabaseName \
        -g $destinationResourceGroup 
fi

# Make sure it gets deleted
while true;
do
    databaseList=$(az sql db list --resource-group $destinationResourceGroup --server $destinationDatabaseServerName  --query '[].name')
    doesDatabaseExist=$(echo $databaseList |jq -r --arg databaseNameToTest "$databaseNameToTest" 'index($databaseNameToTest)')

    if [ $doesDatabaseExist = "null" ]; then
        echo "Database $databaseNameToTest does not exists"
        break
    else   
        echo "Waiting for database $databaseNameToTest delete"
        sleep 5
    fi   
done

echo "Creating database: $destinationDatabaseName"
az sql db create \
    -s $destinationDatabaseServerName \
    -n $destinationDatabaseName \
    -g $destinationResourceGroup \
    --edition Standard \
    --service-objective S0 \
    --catalog-collation DATABASE_DEFAULT

# Initial wait for Azure
sleep 15

# Wait until fully created
while true;
do
    databaseList=$(az sql db list --resource-group $destinationResourceGroup --server $destinationDatabaseServerName  --query '[].name')
    doesDatabaseExist=$(echo $databaseList |jq -r --arg databaseNameToTest "$databaseNameToTest" 'index($databaseNameToTest)')

    if [ $doesDatabaseExist = "null" ]; then
        echo "Database $databaseNameToTest not fully created"
        sleep 5
    else   
        echo "Database $databaseNameToTest created"
        break
    fi   
done

# Target database must be empty which is why we deleted and re-created
echo "Importing database: $destinationDatabaseName"
az sql db import \
    -s $destinationDatabaseServerName \
    -n $destinationDatabaseName \
    -g $destinationResourceGroup \
    -u $destinationDatabaseUsername \
    -p $destinationDatabasePassword \
    --storage-key "?$sasToken" \
    --storage-key-type SharedAccessKey \
    --storage-uri "https://$storageAccountName.blob.core.windows.net/$containerName/$bacPacName"