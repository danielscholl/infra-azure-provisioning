# Encryption in Transit



## Introduction

This document describes how TLS and mTLS secure different parts of the setup and instruct on how to issue a self-signed certificate and upload it to Istio and AppGW, and how to enable mTLS.

 The setup consists of 3 "parts" of connections:

1. Connection between Client and AppGW (1 on the view)
2. Connection between AppGW and Istio (2 on the view)
3. Connections between the services in k8s cluster  (3 on the view)

All these parts use different types of encryptions and use different certificates. The connections between Client and AppGW are secured by TLS and encrypted by BYOC (bring your own certificate) issued by any public authority such as Let's Encrypt or Entrust. The connections between AppGW and Istio are secured by TLS and the connections inside the cluster are secured by mTLS using BYOC or a self-signed certificate depending on what approach you've chosen.

 To use a self-signed certificate, you should have a set of certificates issued by your CA, or you can use the following repo to generate all necessary certs - 

By default, the scheme on the second view is in use. It means that connections between Client - AppGW and AppGW - Istio are secured by TLS and encrypted using BYOC or Let's Encrypt certificate (if you are not using BYOC).

### How to add custom certificates (first view on a diagram).

This instruction will be based on the certificate bundle received by the script.

1. Prepare certificate bundle. If you don’t have your own certificates, you can run the script to generate certificates.
2. Upload custom certificate in Istio. You should create a secret called **cacerts** in **istio-system** namespace. When you create it, Istio starts using it to sign workload certificates inside k8s cluster. To utilize the new certificates immediately, you just need to restart **istiod** pod.

 First you need to remove the password from intermediate key file:

```bash
openssl rsa -in intermediate-key.pem -out key.unencrypted.pem -passin pass:<your password>
```

 After that let's create k8s secret from existing files:

```bash
kubectl create secret generic cacerts -n istio-system \
   --from-file=ca-cert.pem=2_intermediate/certs/intermediate-cert.pem \
   --from-file=ca-key.pem=2_intermediate/private/key.unencrypted.pem \
   --from-file=root-cert.pem=1_root/certs/root-cert.pem \
   --from-file=cert-chain.pem=2_intermediate/certs/ca-chain.cert.pem
```

After that you have to restart istiod and istio-ingress gw deployments.

3. Upload "Application" certificate in Istio to secure traffic between     AppGW and Istio.

You should create a secret with some name, let it be 'appgw-credential'. This secret should contain certificate chain and private part of Application certificate. Create new file named **full.cer** in *2_intermediate/certs/*. This file should consist from 3 certs: *2_intermediate\ca-chain.cert.pem* and *3_application/private/test.com-cert.pem*. Insert content of *test.com-cert.pem* in *full.cer*, then insert content of *ca-chain.cert.pem* using notepad.

After that let's create k8s secret from existing files:

```bash
kubectl create -n istio-system secret generic appgw-credential --from-file=tls.key=3_application/private/test.com-key.pem \

  --from-file=tls.crt=2_intermediate/certs/full.cer
```

 Also, you need to configure Istio Gateway to utilize appgw-credential secret and set tls mode to SIMPLE. 

4. Upload Trusted Root     Certificate to AppGW to whitelist custom certificate.

Open Istio AppGW (called *istio-gw) in Azure portal, go to HTTP settings, open an entry using 443 port, set "Use well known CA certificate" check button to "No" and upload there full.cer file

5. Check if all backends are healthy in the Backend health blade.

 
## How to enable mTLS in services cluster.
 
Feature flag `isMtlsEnabled` is responsible for enabling and disabling of mTLS. By default, this feature flag is set to 'false'.
To enable mTLS you should set the flag to 'true'. To do it you need to add variable `ENABLE_ISTIO_mTLS` in Azure Target Env - <env> variable group and set it to 'true'.

 
