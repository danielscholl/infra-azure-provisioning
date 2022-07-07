from __future__ import print_function
import os
import sys
import time
import asyncio as aio
import requests
import json
from json.decoder import JSONDecodeError
from pprint import pprint
from utils import getAccessToken, isSuccessStatusCode, isRetryableFailureStatusCode, isNonRetryableFailureStatusCode, terminateIstioSidecar, getKeyVaultName, replacePlaceholderWithSecretValue
from configmap_utils import writeOutputToConfigMap

## Environment Variables ##
AzureSubscription = os.environ['SUBSCRIPTION']
AzureResourceGroup = os.environ['RESOURCE_GROUP_NAME']
AzureIdentityId = os.environ['OSDU_IDENTITY_ID']
CustomerAdminIds = os.environ['ADMIN_IDS']
ServiceDomain = os.environ['SERVICE_DOMAIN']
OsduHost = os.environ['OSDU_HOST']
Partitions = os.environ['PARTITIONS'].strip().split(',')
Partitions = [env_partition.strip() for env_partition in Partitions]
ConfigMapName = os.environ['CONFIG_MAP_NAME']
Namespace = os.environ['NAMESPACE']
KeyVaultName = getKeyVaultName(AzureSubscription, AzureResourceGroup)

## Global Props ##
toInitPartition = True
toInitEntitleMents = True

token = ""
status = { "ops": True }
message = {"ops": ""}
for part in Partitions:
    status[part] = True
    message[part] = {"ops": "", "initPartition": "", "initEntitlements": ""}

config_json = {}
with open('config.json', 'r') as config_file:
    config_json = json.loads(config_file.read()) 

partitionHost = config_json["services"]["partition"]["hostUrl"].format(namespace=Namespace)
partitionInitApiFormat = config_json["services"]["partition"]["api"]["partition-init"]

entitlementsHost = config_json["services"]["entitlements"]["hostUrl"].format(namespace=Namespace)
entitlementsInitApiFormat = config_json["services"]["entitlements"]["api"]["tenant-init"]
entitlementsAddUserApiFormat = config_json["services"]["entitlements"]["api"]["add-user"]
entitlementsAddOpsUserApiFormat = config_json["services"]["entitlements"]["api"]["add-ops-user"]
entitlementsAddRootUserApiFormat = config_json["services"]["entitlements"]["api"]["add-root-user"]

""" [Logging Functions]
These will format the logs, print the log to the console, as well as append logs to appropriate section in the message to be written to the configmap for tracking. 
"""
def log(*logStr):
    global message

    joinedLog = ' '.join(logStr)
    message["ops"] = message["ops"] + joinedLog + " ... "
    
    print(joinedLog)

def logApi(logString, attemptCount=0, partition="", url="", statusCode=-1, data=""):
    global message
    
    joinedLog = "API Log for attempt Count {attemptCount} for Partition {partition} for URL {url} -> Returned Status Code: {statusCode} and Reponse: {data} -> Log Message: {logString}".format(attemptCount=str(attemptCount), partition=partition, url=url, statusCode=str(statusCode), data=data, logString=logString)
    
    message["ops"] = message["ops"] + joinedLog + " ... "
    print(joinedLog)

def logAsync(*logStr):
    global message

    partition = logStr[0]
    joinedLog = ' '.join(logStr[1:])
    message[partition]["ops"] = message[partition]["ops"] + joinedLog + " ... "
    joinedLog = "Partition " + partition + ": " + joinedLog
    print(joinedLog)

def logPartitionAsync(*logStr):
    global message

    partition = logStr[0]
    joinedLog = ' '.join(logStr[1:])
    message[partition]["initPartition"] = message[partition]["initPartition"] + joinedLog + " ... "
    joinedLog = "Init Partition for Partition " + partition + ": " + joinedLog
    print(joinedLog)

def logEntitlementsAsync(*logStr):
    global message

    partition = logStr[0]
    joinedLog = ' '.join(logStr[1:])
    message[partition]["initEntitlements"] = message[partition]["initEntitlements"] + joinedLog + " ... "
    joinedLog = "Init Entitlements for Partition " + partition + ": " + joinedLog
    print(joinedLog)

""" [Post Call Helper Function]
Method to make the post calls to services, parse the responses, and log the responses appropriately, with an attached retry mechanism based on the response received. 
"""
async def servicePostApiCall(url, partition, data="", attemptCount=1):
    global token
    
    body = ""
    if type(data) is dict:
        body = json.dumps(data)
    elif type(data) is str:
        body = data
    else:
        body = str(data)
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + token,
        "data-partition-id": partition
    }
    
    responseStatusCode = 0
    responseDataJson = ""
    
    try:
        response = requests.post(url, headers=headers, data=body, timeout=None)
    
        if response is None:
            if attemptCount < 3:
                logApi(logString="Null response received, RETRYING call", attemptCount=attemptCount, partition=partition, url=url, statusCode=-1, data=responseDataJson)
                
                return await aio.create_task(servicePostApiCall(url, partition, data, attemptCount=(attemptCount + 1)))
            else:
                logApi(logString="Null response received, ABORTING call", attemptCount=attemptCount, partition=partition, url=url, statusCode=-1, data=responseDataJson)
                
                return { "isSuccess": False, "statusCode": 0, "data": "" }
        
        responseStatusCode = response.status_code
        responseDataJson = ""
        try:
            responseDataJson = response.json()
        except JSONDecodeError:
            logApi(logString="JSONDecodeError encountered when trying to read response data as json", attemptCount=attemptCount, partition=partition, url=url, statusCode=0, data="JSONDecodeError")
            responseDataJson = "{url} did not return a json-parseable response".format(url=url)
        
        response.close()
    except requests.exceptions.Timeout as toex:
        logApi(logString="Timeout exception thrown, RETRYING call, Timeout Exception: " + json.dumps(toex), attemptCount=attemptCount, partition=partition, url=url, statusCode=-1, data=responseDataJson)
        
        responseStatusCode = 0
    except requests.exceptions.TooManyRedirects as tmrex:
        logApi(logString="Too Many Redirects exception thrown, ABORTING call, TooManyRedirects Exception: " + json.dumps(tmrex), attemptCount=attemptCount, partition=partition, url=url, statusCode=-1, data=responseDataJson)
        
        responseStatusCode = -1
    except requests.exceptions.RequestException as reqEx:
        logApi(logString="Request exception thrown, ABORTING call, RequestException Exception: " + json.dumps(reqEx), attemptCount=attemptCount, partition=partition, url=url, statusCode=-1, data=responseDataJson)
        
        responseStatusCode = -1
    
    if isSuccessStatusCode(responseStatusCode):
        logApi(logString="SUCCESS", attemptCount=attemptCount, partition=partition, url=url, statusCode=responseStatusCode, data=responseDataJson)
        
        return { "isSuccess": True, "statusCode": responseStatusCode, "data": responseDataJson }
    elif attemptCount >= 3:
        logApi(logString="FAILED & MAX retry attempts reached, ABORTING...", attemptCount=attemptCount, partition=partition, url=url, statusCode=responseStatusCode, data=responseDataJson)
        
        return { "isSuccess": False, "statusCode": responseStatusCode, "data": responseDataJson }
    else:
        if isRetryableFailureStatusCode(responseStatusCode):
            logApi(logString="FAILED, Retriable failure status code, RETRYING...", attemptCount=attemptCount, partition=partition, url=url, statusCode=responseStatusCode, data=responseDataJson)
            
            log("Fetching Access Token")
            token = getAccessToken()
            if token == "Token Fetch Failed":
                log("Fetching Access Token Failed")
            else:
                log("Fetched Access Token Successfully")
            
            return await aio.create_task(servicePostApiCall(url, partition, data, attemptCount=(attemptCount + 1)))
        elif isNonRetryableFailureStatusCode(responseStatusCode):
            logApi(logString="FAILED, Non-Retriable failure status code, ABORTING...", attemptCount=attemptCount, partition=partition, url=url, statusCode=responseStatusCode, data=responseDataJson)
            
            return { "isSuccess": False, "statusCode": responseStatusCode, "data": responseDataJson }
        else:
            logApi(logString="FAILED, unaccounted failure status code, ABORTING...", attemptCount=attemptCount, partition=partition, url=url, statusCode=responseStatusCode, data=responseDataJson)
            
            return { "isSuccess": False, "statusCode": responseStatusCode, "data": responseDataJson }
    return { "isSuccess": False, "statusCode": -1, "data": "Unaccounted return statement encountered." }

""" [Partition Initialization]
Async Partition Initialization process for a single partition by calling the partition init API, and updating the status. 
"""
async def initializePartition(partition):
    global status
    global toInitPartition
    global partitionHost
    global partitionInitApiFormat
    
    logPartitionAsync(partition, "Partition Host: ", partitionHost)
    
    if not toInitPartition:
        logPartitionAsync(partition, "Skipping Partition Initialization since disabled")
        return
    
    partitionInitApi = partitionInitApiFormat.format(partitionHost=partitionHost, partition=partition)

    with open('partition_init_payload.json', 'r') as requestBodyFile:
        requestBody = requestBodyFile.read()
        try:
            requestBody = replacePlaceholderWithSecretValue(requestBody, KeyVaultName, partition)
            logPartitionAsync(partition, "Initializing partition {partition}, using URL {url}".format(partition=partition, url=partitionInitApi))
            response = await aio.create_task(servicePostApiCall(url=partitionInitApi, partition=partition, data=requestBody))
            if response["isSuccess"]:
                logPartitionAsync(partition, "Partition Initialization for {partition} SUCCESSFUL with status code {statusCode}, and returned response \"{response}\"".format(partition=partition, statusCode=response["statusCode"], response=response["data"]))
            else:
                logPartitionAsync(partition, "Partition Initialization for {partition} FAILED with status code {statusCode}, and returned response \"{response}\"".format(partition=partition, statusCode=response["statusCode"], response=response["data"]))
                status[partition] = False
        except Exception as e:
            logPartitionAsync(partition, e)
            status[partition] = False

    return

""" [Entitlements Initialization]
Async Entitlements Initialization process for a single partition by calling the tenant init API for the pod identity, then granting a similar privilege to customer provided Object ID by adding the oid to 3 entitlement groups (user, ops user, root user). Update the status as needed. 
"""
async def initializeEntitlements(partition):
    global status
    global toInitEntitleMents
    global entitlementsHost
    global entitlementsInitApiFormat
    global entitlementsAddUserApiFormat
    global entitlementsAddOpsUserApiFormat
    global entitlementsAddRootUserApiFormat
    global entitlementsAddUsersRequestBody
    global ServiceDomain
    global CustomerAdminIds
    
    logEntitlementsAsync(partition, "Entilements Host: ", entitlementsHost)
    
    if not toInitEntitleMents:
        logEntitlementsAsync(partition, "Skipping Entitlements Initialization since disabled")
        return
    
    entitlementsInitApi = entitlementsInitApiFormat.format(entitlementsHost=entitlementsHost)
    
    logEntitlementsAsync(partition, "Commencing tenant provisioning for partition {partition}, using URL {url}".format(partition=partition, url=entitlementsInitApi))
    
    init_response = await aio.create_task(servicePostApiCall(url=entitlementsInitApi, partition=partition))
        
    if init_response["isSuccess"]:
        logEntitlementsAsync(partition, "Tenant Provisioning for {partition} SUCCESSFUL with status code {statusCode}, and returned response \"{response}\"".format(partition=partition, statusCode=init_response["statusCode"], response=init_response["data"]))
        
        admin_entitlements_tasks = []

        for CustomerAdminId in CustomerAdminIds.split(','):
            entitlementsAddUsersRequestBody = {"email": CustomerAdminId, "role": "OWNER"}
        
            entitlementsUserApi = entitlementsAddUserApiFormat.format(entitlementsHost=entitlementsHost, partition=partition, serviceDomain=ServiceDomain)
        
            logEntitlementsAsync(partition, "Adding Entitlements for Customer Admin as a USER for partition {partition}; URL:{url}".format(partition=partition, url=entitlementsUserApi))
        
            admin_entitlements_tasks.append(aio.create_task(servicePostApiCall(url=entitlementsUserApi, partition=partition, data=entitlementsAddUsersRequestBody)))
        
            entitlementsOpsApi = entitlementsAddOpsUserApiFormat.format(entitlementsHost=entitlementsHost, partition=partition, serviceDomain=ServiceDomain)
        
            logEntitlementsAsync(partition, "Adding Entitlements for Customer Admin as an OPS USER for partition {partition}; URL:{url}".format(partition=partition, url=entitlementsOpsApi))
        
            admin_entitlements_tasks.append(aio.create_task(servicePostApiCall(url=entitlementsOpsApi, partition=partition, data=entitlementsAddUsersRequestBody)))
        
            entitlementsRootApi = entitlementsAddRootUserApiFormat.format(entitlementsHost=entitlementsHost, partition=partition, serviceDomain=ServiceDomain)
        
            logEntitlementsAsync(partition, "Adding Entitlements for Customer Admin as a ROOT USER for partition {partition}; URL:{url}".format(partition=partition, url=entitlementsRootApi))
        
            admin_entitlements_tasks.append(aio.create_task(servicePostApiCall(url=entitlementsRootApi, partition=partition, data=entitlementsAddUsersRequestBody)))
        
        logEntitlementsAsync(partition, "Collecting Entitlement Group Addition Calls")
        while True:
            finished, unfinished = await aio.wait(admin_entitlements_tasks, return_when=aio.FIRST_COMPLETED)

            for finished_task in finished:
                admin_response = finished_task.result()
                if admin_response["isSuccess"]:
                    logEntitlementsAsync(partition, "An Entitlements Group Addition call for {partition} SUCCESSFUL with status code {statusCode}, and returned response \"{response}\"".format(partition=partition, statusCode=admin_response["statusCode"], response=admin_response["data"]))
                else:
                    status[partition] = False
                
                    logEntitlementsAsync(partition, "An Entitlements Group Addition call for {partition} FAILED with status code {statusCode}, and returned response \"{response}\"".format(partition=partition, statusCode=admin_response["statusCode"], response=admin_response["data"]))

            if len(unfinished) == 0:
                break
            admin_entitlements_tasks = unfinished
        logEntitlementsAsync(partition, "Collected All Entitlement Group Addition Calls")
                
    else:
        status[partition] = False
        
        logEntitlementsAsync(partition, "Tenant Provisioning for {partition} FAILED with status code {statusCode}, and returned response \"{response}\"".format(partition=partition, statusCode=init_response["statusCode"], response=init_response["data"]))
        logEntitlementsAsync(partition, "Skipping subsequest steps since prerequisite call failed.")
    return

""" [Instance Partition Initialization]
Async Instance Initialization process for a single partition and updating the status. 
"""
async def initializeInstancePartition(partition):
    global status

    logAsync(partition, "Started Thread for Instance Initialization")
    
    logAsync(partition, "Starting Partition Initialization")
    await aio.create_task(initializePartition(partition))
    logAsync(partition, "Completed Partition Initialization")
    
    if not status[partition]:
        logAsync(partition, "Skipping Entitlements Initialization since Partition Initialization failed")
    
    logAsync(partition, "Starting Entitlements Initialization")
    await aio.create_task(initializeEntitlements(partition))
    logAsync(partition, "Completed Entitlements Initialization")
    
    logAsync(partition, "Ending Thread for Instance Initialization")
    
    return partition

""" [Instance Initialization]
Async Instance Initialization process for a multiple partitions, which spawn async processes for each partition, and collects the responses for each partition. 
"""
async def performInstanceInitialization():
    global status

    if not status["ops"]:
        log("Skipping Instance Initialization since initial status showed failure")
        return
    
    tasks = []
    for partition in Partitions:
        log("Initializing Instance For Partition: ", partition)
        tasks.append(aio.create_task(initializeInstancePartition(partition)))

    while True:
        finished, unfinished = await aio.wait(tasks, return_when=aio.FIRST_COMPLETED)
        
        for fin in finished:
            log("Finished & collected Initialization results for Partition ", fin.result())
        
        if len(unfinished) == 0:
            break
        tasks = unfinished
    return

def main():
    global status
    global message
    global ConfigMapName
    global Namespace
    global Partitions
    
    try:
        log("Fetching Access Token")
        token = getAccessToken()
        if token == "Token Fetch Failed":
            status["ops"] = False
            log("Fetching Access Token Failed")
        else:
            log("Fetched Access Token Successfully")
        
        aio.run(performInstanceInitialization())
    except Exception as ex:
        status["ops"] = False
        log("Catastrophic Unhandled Exception encountered: {exception}".format(exception=json.dumps(ex)))
    finally:
        writeOutputToConfigMap(status=status, message=message, ConfigMapName=ConfigMapName, Namespace=Namespace, Partitions=Partitions)
        terminateIstioSidecar()

if __name__ == '__main__':
    main()