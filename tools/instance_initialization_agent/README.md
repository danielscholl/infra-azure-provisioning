# Steps to run the docker container -

## Step 1:
Navigate to this location in the loca repo (~/tools/instance_initialization_agent)

## Step 2:
Connect to an ACR
```bash
az login
az account set -s <Subscription_Name>
az acr login -n <ACR_Name>
```

## Step 3:
Build & push the docker container to the ACR
```bash
docker build . -t <ACR_Name>.azurecr.io/instance-init:1.0.0
docker push <ACR_Name>.azurecr.io/instance-init:1.0.0
```

## Step 4:
Connect to the AKS Cluster:
```bash
az login
az account set -s <Subscription_Name>
az aks get-credentials --resource-group <resource_group_name> --name <aks_cluster_name>
kubectl config set-context <resource_group_name> --cluster <aks_cluster_name>
```

## Step 5:
To deploy the job to the AKS cluster:
- Clone the [helm-charts-azure repo](https://community.opengroup.org/osdu/platform/deployment-and-operations/helm-charts-azure)
- Navigate to ~/osdu-azure/osdu-instance-initialization
- Follow the README to populate the values file, and perform the helm installation to deploy the job to the AKS cluster, with the required values set.

## Step 6:
Check the pod logs:
```bash
kubectl get pods -n <namespace> | grep instance-init #Get the pod name from the output
kubectl logs -c instance-init -f <pod_name> -n <namespace>

# OR, Check the config map contents, if the pod has completed
kubectl describe configmap <configmap_name> -n <namespace>
```