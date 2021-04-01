[[_TOC_]]
## Introduction
This wiki talks about how to migrate data from one cosmos db to another cosmos db. The migration happens at db level and one can choose what all containers from which you want to migrate data.

## Identify Source database
The source data base account would be the one created after restore. The name of database would be `<Azure_Cosmos_account_original_name>-restored1`, unless you have specified differently. The last digit is incremented when multiple restores are attempted. Pick the databases in this account one by one and repeat the process for all the dbs.

## Identify destination database
The destination database account would be the original cosmos db account on which you ran the restore operation. Pick the database same as one you picked in the previous step.

## Clean up destination database
Since we are migrating data from recovered database, most of the data in original database would be same as that in recovered one. The copy activity in Azure Data Factory does not support data overwrite and hence you need to clean up the destination database before starting the migration.

This [stackoverflow thread](https://stackoverflow.com/questions/45869002/delete-all-multiple-documents-from-azure-cosmos-db-through-the-portal) talks about how you can achieve the data cleanup. As mentioned in the link, you can either set the `Time to live` to `1 seconds` temporarily by following [these](https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-time-to-live?tabs=dotnetv2%2Cjavav4) steps, ensure that all the data is gone from cosmos container and disable the time to live again. Note that **disabling it back is important**, otherwise any data that you write to the concerned cosmos container would be wiped away automatically. Once you disable it back, cross check that all the records are indeed deleted.

**NOTE**- Time taken for document deletion to complete depends on number of documents you have in the cosmos collection. If the number of documents is more than 1M, then expect it to take 30+ minutes.

 Alternatively you can write a [stored procedure](https://github.com/Azure/azure-cosmosdb-js-server/blob/master/samples/stored-procedures/bulkDelete.js) to cleanup data and use that.


## Prepare for migration
We'll migrate data from new cosmos db to the older db using Azure Data Factory (aka ADF). ADF offers support for both CLI and from azure portal. For this exercise, we'll use azure portal however equivalent CLI commands are also available.

## Start data migration using ADF

Read the overview of ADF [here](https://docs.microsoft.com/en-us/azure/data-factory/introduction#:~:text=Azure%20Data%20Factory%20is%20the,and%20transforming%20data%20at%20scale.).
### Create a data factory Instance
Create the ADF instance by following instructions [here](https://docs.microsoft.com/en-us/azure/data-factory/quickstart-create-data-factory-portal#create-a-data-factory)

### Create a copy activity
Go to the `Author & Monitor` section from your data factory instance.

![select-monitor](images/backup-restore/monitor-selection.png)

Select the `Copy Data` option.

![image.png](/.attachments/image-d9ab8657-5697-4345-a2cd-11849c8ba9da.png)

Provide name and description for your task. Click `Next`

![image.png](/.attachments/image-367d9dcb-9958-4eb9-9091-6e8f5f7ee6c3.png)

### Create a linked service for source

Select the `+ Create New Connection` to create new connection service.

![image.png](/.attachments/image-29a172a4-21f3-4b6d-8b91-a43d5f1c6cc5.png)

Choose Azure Cosmos DB as source activity.

**NOTE**- please choose MongoDB API or SQL API as required. 

![image.png](/.attachments/image-9e75a7f1-5ce9-4b28-9ebd-910db53e6316.png)

Fill out required details. Connection settings of the cosmos databases would be picked up automatically.

![image.png](/.attachments/image-50f05d13-f4af-402c-9176-00f6fe06b9c9.png)

Select the containers you want to migrate data from. For your case you want to select all the containers.

![image.png](/.attachments/image-68eac15c-48fd-42e6-82a8-fa1525fe0a8e.png)

### Create a linked service for sink

**NOTE**- please choose MongoDB API or SQL API as required. 

Choose Azure Cosmos DB  as sink activity. Fill out the necessary details. Click `Create` and then click `Next`

![image.png](/.attachments/image-a4bdbf43-5558-4c87-81c5-9a271f9fb17f.png)

Validate the table mapping. The destination table name would be populated automatically. You can pick the appropriate container from the dropdown if it doesn't populate on it's own.

![image.png](/.attachments/image-98b6ea2b-8926-4389-aa82-f14c529bdd31.png)

Configure logging properties. You can optionally create a linked logging service to persist logs in blobs.

![image.png](/.attachments/image-5b5a0476-ec05-40f5-a3b8-1818e4f4f69d.png)

Review and run.

![image.png](/.attachments/image-ea58f87a-f75b-47ff-9970-fed546ad998d.png)

You can monitor the pipelines by going to the monitor pivot.

![image.png](/.attachments/image-01b44a0e-3f0d-4b9e-9360-0ab751c229f3.png)

## Validate the migrated data
Compare the data in target containers with source containers manually to see if the migrated data is what you expect it to be.


## Cleanup the provisioned resources.

Delete the azure data factory that you created in this step to avoid extra cost.
![image.png](/.attachments/image-8a000348-9256-4526-9b36-62e189488ead.png)
