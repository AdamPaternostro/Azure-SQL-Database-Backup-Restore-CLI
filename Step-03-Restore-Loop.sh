# Loop over the JSON and restore the database {x} times per the JSON
# Assume the server exists
# In order to import the database, the destination database must be empty. 
# So this script will delete the current database, create a new empty one with the same name, then import
# Requires (JQ): https://stedolan.github.io/jq/download/
# Reads the file restore.json

################################
# Variables
################################
sasToken='mygeneratedsastoken'
bacPacName=mybacpac.bacpac
containerName=bacpacs
storageAccountName=mystorageaccountname


################################
# Select the correct subscription
################################
# az login is not needed in the Azure Cloud Shell
# az login


################################
# Delete the existing database
# Create a new one (same name)
# Import database
################################
json=$(cat restore.json)

for row in $(echo $json | jq -c '.[]'); do
    destinationSubscriptionId=$(echo ${row} | jq -r .destinationSubscriptionId)
    destinationDatabaseServerName=$(echo ${row} | jq -r .destinationDatabaseServerName)
    destinationDatabaseName=$(echo ${row} | jq -r .destinationDatabaseName)
    destinationResourceGroup=$(echo ${row} | jq -r .destinationResourceGroup)
    destinationDatabaseUsername=$(echo ${row} | jq -r .destinationDatabaseUsername)
    destinationDatabasePassword=$(echo ${row} | jq -r .destinationDatabasePassword)

    echo $destinationSubscriptionId
    echo $destinationDatabaseServerName
    echo $destinationDatabaseName
    echo $destinationResourceGroup
    echo $destinationDatabaseUsername
    # echo $destinationDatabasePassword

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
done