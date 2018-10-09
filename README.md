# Azure-SQL-Database-Backup-Restore-CLI
Shows how to backup and restore a SQL Database using Azure CLI.  Performs the restore process in a loop (optional) for restoring over several destinations in an easy manner.

### How it works
See each script for the parameters you need to change

1. Step 01 - A shared access token is generated for a container in Azure Storage (typically an Admin would run this).
2. Step 02 - You can do a backup or a backup and restore
3. Step 03 - You can do a restore to a single database or a loop in case you want to restore a production copy to QA, Dev, Demo, etc.
