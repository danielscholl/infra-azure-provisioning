import json
from kubernetes import client, config
from kubernetes.client.rest import ApiException
from json.decoder import JSONDecodeError
from pprint import pprint

""" [Config Map Exception Helper]
Check if a config map process has failed due to the message being too long. 
"""
def checkIfConfigMapLengthException(ex):
    ex_body = json.loads(e.body)
    code = ex_body["code"]
    stringCode = code if type(code) is str else str(code)
    ex_details = json.dumps(ex_body["details"])
    
    if stringCode == "422" or "FieldValueTooLong" in ex_details:
        return True
    return False

""" [Read from Config Map]
Read the existing contents of a config map, with a retry mechanism.
"""
def readFromConfigMap(attemptNum, ConfigMapName, Namespace):
    retryRead = False
    readStatus = True
    readMessage = ""
    print("Read From Config Map, Attempt ", str(attemptNum + 1))

    config.load_incluster_config()
    # Enter a context with an instance of the API kubernetes.client
    # https://github.com/kubernetes-client/python/tree/master/kubernetes/client
    # https://raw.githubusercontent.com/kubernetes-client/python/master/kubernetes/docs/CoreV1Api.md
    with client.ApiClient() as api_client:
        # Create an instance of the API class
        api_instance = client.CoreV1Api(api_client)

        try:
            api_response = api_instance.read_namespaced_config_map(ConfigMapName, Namespace, pretty='true')
            # print("Read Config Map: ") # DEBUG
            # pprint(api_response) # DEBUG
            
            readStatus = api_response.data["status"] == "success"
            readMessage = api_response.data["message"]
            
            print("Read From Config Map SUCCESS, Attempt ", str(attemptNum + 1))
            return {"status": readStatus, "message": readMessage, "v1Config": api_response}
        except ApiException as e:
            print("Exception when calling CoreV1Api->read_namespaced_config_map")
            print("Exception: ", e)
            print("Read From Config Map FAILURE, Attempt ", str(attemptNum + 1))
            
            if isRetryableFailureStatusCode(json.loads(e.body)["code"]):
                retryRead = True
    
    if retryRead and attemptNum <= 1:
        return readFromConfigMap(attemptNum=(attemptNum + 1), ConfigMapName=ConfigMapName, Namespace=Namespace)
    return {"status": readStatus, "message": readMessage}

""" [Write to Config Map]
Write to the config map, with a retry mechanism, handling is message is too long to communicate. Returns the value of finalStatus
"""
def writeOutputToConfigMap(status, message, ConfigMapName, Namespace, Partitions):
    configmapWriteHistory = 1
    finalStatus = True

    print("Final Status: ")
    pprint(status)
    print("Final Message: ")
    pprint(message)

    readConfig = readFromConfigMap(attemptNum = 0, ConfigMapName=ConfigMapName, Namespace=Namespace)
    # print("Config Map Existing Status: ", readConfig["status"]) # DEBUG
    # print("Config Map Existing Message: ", readConfig["message"]) # DEBUG
    
    configmapWriteType = "Create"
    if ("v1Config" in readConfig) and (not (readConfig["v1Config"] is None)):
        configmapWriteType = "Patch"
    
    attemptCount = 0
    while True:
        attemptCount = attemptCount + 1
        print("Write To Config Map, Attempt ", str(attemptCount))
        writeSuccess = False
        
        existingMessage = {}
        try:
            existingMessage = readConfig["message"] if type(readConfig["message"]) is dict else json.loads(readConfig["message"])
        except JSONDecodeError as j:
            print("Existing message could not be loaded as json")
            pprint(j)
        except Exception as ex:
            print("Exception encountered while attempting to read message")
            pprint(ex)
        
        if configmapWriteHistory == 1:
            existingMessage["previousIteration"] = "~~REDACTED~~" # Removing >=2 level historical info to adhere to config map length constraints
        else:
            existingMessage = {"message": "~~REDACTED~~"} # Removing All historical info to adhere to config map length constraints
        
        finalStatus = status["ops"]
        for partitionEval in Partitions:
            finalStatus = finalStatus and status[partitionEval]
        statusToWrite = "success" if finalStatus else "failure"
        messageToWrite = { "granularStatus": status, "currentIteration": message if configmapWriteHistory >= 0 else "~~REDACTED~~", "previousIteration": existingMessage }
        configdata = { "status": str(statusToWrite), "message": json.dumps(messageToWrite) }
        
        config.load_incluster_config()
        with client.ApiClient() as api_client:
            api_instance = client.CoreV1Api(api_client)
            
            if configmapWriteType == "Create":
                try:
                    metadata = client.V1ObjectMeta(name=ConfigMapName)
                    config_map = client.V1ConfigMap(api_version="v1", kind="ConfigMap", data=configdata, metadata=metadata)
                    
                    api_response = api_instance.create_namespaced_config_map(namespace=Namespace, body=config_map, pretty='true', field_manager=ConfigMapName)
                    # print("Create Config Map: ") # DEBUG
                    # pprint(api_response) # DEBUG
                    
                    writeSuccess = True
                    print("Write to Config Map SUCCESS, Attempt ", str(attemptCount))
                except ApiException as e:
                    print("Exception when calling CoreV1Api->create_namespaced_config_map")
                    print("Exception: ", e)
                    print("Write to Config Map FAILURE, Attempt ", str(attemptCount))
                    
                    if checkIfConfigMapLengthException(e):
                        configmapWriteHistory = configmapWriteHistory - 1
            else:
                try:
                    config_map = client.V1ConfigMap(api_version="v1", kind="ConfigMap", data=configdata, metadata=readConfig["v1Config"].metadata)
                    
                    api_response = api_instance.patch_namespaced_config_map(name=ConfigMapName, namespace=Namespace, body=config_map, pretty='true', field_manager=ConfigMapName)
                    # print("Patch Config Map: ") # DEBUG
                    # pprint(api_response) # DEBUG
                    
                    writeSuccess = True
                    print("Write to Config Map SUCCESS, Attempt ", str(attemptCount))
                except ApiException as e:
                    print("Exception when calling CoreV1Api->patch_namespaced_config_map")
                    print("Exception: ", e)
                    print("Write to Config Map FAILURE, Attempt ", str(attemptCount))
                    
                    if checkIfConfigMapLengthException(e):
                        configmapWriteHistory = configmapWriteHistory - 1
        
        if attemptCount >= 3 or writeSuccess:
            break

    return finalStatus
