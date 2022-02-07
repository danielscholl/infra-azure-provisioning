import requests
import json

def convertToInt(code):
    if type(code) is int:
        return code
    elif type(code) is str:
        try:
            if (not (code is None)) and (code) and (not code.isspace()):
                return int(code)
            else:
                print("Convert to Int received Null, Empty or Whitespace string")
                return -1
        except Exception as ex:
            print("Exception thrown when converting string to int")
            return 0
    else:
        print("Encountered non-int non-string code to convert to type INT, type found: ", type(code))
        try:
            return int(code)
        except Exception as ex:
            print("Exception thrown when converting unaccounted type to int")
            return 0

""" [HTTP Status Code Check Functions]
Check is the status code returned by a http request is a success, a retriable failure, or a non-retriable failure. 
"""
def isSuccessStatusCode(exStatusCode):
    statusCode = convertToInt(exStatusCode)
    
    if (statusCode >= 200 and statusCode <= 299) or (statusCode == 409):
        return True
    return False

def isRetryableFailureStatusCode(exStatusCode):
    statusCode = convertToInt(exStatusCode)
    if statusCode == 0:
        print("Retriable Empty Status Code.")
        
        return True
    elif (statusCode == 401) or (statusCode == 403):
        print("Unauthorized/Forbidden HTTP Status Code encountered. Re-fetching Access Token...")
        
        return True
    elif statusCode == 429:
        print("Throttled HTTP Status Code encountered. Sleeping...")
        sleepTimeInSeconds = 30
        
        print("Sleeping for ", str(sleepTimeInSeconds), " seconds.")
        print.sleep(sleepTimeInSeconds)
        
        return True
    elif statusCode >= 500 and statusCode <= 599:
        print("Server Error Code: ", statusCode, " encountered. No Action, but retrying...")
        
        return True
    return False

def isNonRetryableFailureStatusCode(exStatusCode):
    statusCode = convertToInt(exStatusCode)
    if (statusCode == 400) or (statusCode == 404) or (statusCode == -1):
        return True
    return False

""" [Fetch Access Token Function]
Fetch the access token for a pod identity associated with the docker container, with a retry mechanism. 
"""
def getAccessToken():
    for i in range(3):
        url = 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F'
        headers = {
            "Metadata": "true"
        }

        response = requests.get(url, headers=headers)

        if (response is None) or (response.status_code != 200):
            print("Fetching Access Token Failed: ", response)
            continue
        
        print("Fetched Access Token Successfully")
        token = response.json()["access_token"]

        if (token is None) or (not token) or (token.isspace()):
            print("Invalid Token: ", token)
            continue
        
        print("Valid Token")
        return token
    return "Token Fetch Failed"

""" [Terminate Istio side-car Functions]
Terminate the istio side-car once processing has completed, so the job can reach a completed state.
"""
def terminateIstioSidecar():
    try:
        response = requests.post("http://localhost:{SIDECAR_PORT}/quitquitquit".format(SIDECAR_PORT="15020"))
        
        if response is None:
            print("Terminating Istio Side-car returned null response")
        else:
            print("Terminating Istio side-car returned status code {code}".format(code=response.status_code))
    except Exception as ex:
        print("Terminating Istio Side-car threw exception: {exception}".format(exception=json.dumps(ex)))