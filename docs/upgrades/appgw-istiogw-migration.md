# Moving from appgw to istiogw (M14 - 0.17.0)

Referenced issues:

* [Community issue](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/issues/236)]

1. Deploy latest M14 terraform scripts version. (It will deploy the application gateway).
2. Make sure the `osdu-istio` release it is installed [osdu-istio](https://community.opengroup.org/osdu/platform/deployment-and-operations/helm-charts-azure/-/tree/v0.16.0/osdu-istio), you can check that with `helm ls -n istio-system`, check that osdu-istio release it is installed correctly.
    * Additionally check if istio gateway is up and running: `kubectl get svc -n istio-system istio-ingressgateway`
    * If it is not check troubleshooting section for istio [Pending status](appgw-istiogw-migration.md#Troubleshooting)
3. You can check that all services are up and running by checking the new istioappgw, check for ip address in the azure console for istio-gw resource.
    * Modify your `/etc/hosts` file and add temporary entry.
    * `curl -H "Host: <your fqdn>" https://ip-address-istio-appgw/api/partition/v1/api-docs`
4. Change your old dns hostname to new istio appgw (With your dns provider).

## Troubleshooting

* __Istio internall LB in pending state__
  * Most likely AKS control plane don't have access yet to the network, therefore you need to apply changes in the latest terraform code.
* __AppGw Certificate issues__
  * Check logs for cert-checker job in istio-system namespace, you can as well modify the value in the settings of the https of the appgw and configure it manually if needed or if you're using BYOC.
  * We had see that sometimes the job will not be able to get the lets-encrypt certificate from the osdu namespace to the istio-system namespace, would need to update that accordingly or figure out error with the job.
  * When you try to generate new certificate from the ACME and cert manager, you may notice that ingress it will be created but not able to expose the http response from the certificate generator, you can overcome this by adding in istiogw:
  * As well to create service to expose that cert-manager endpoint, I.E:

```yaml
      - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
        - "{{ .Values.global.istio.dns_host }}"
```

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: cm-acme
  namespace: istio-system
spec:
  gateways:
  - istio-system/istio-gateway
  hosts:
  - <host-fqdn>
  # Got from the acme resolver
  http:
  - match:
    - uri:
        prefix: /.well-known/acme-challenge/w-xxxxx_yyy
    route:
    - destination:
        host: cm-acme-http-solver-xxxxx
        port:
          number: 8089
```

* __502 Responses from AppGw__
  * Check health probes/rules/backend pools in agic and why are those failing, we are configuring for istio-gw only one redirection to the internal istio lb.
* __Brownfield move if autoscale flag was enabled__
  * In case you already have the istiogw operational, you may not want to remove with new terraform plan and apply, to avoid this you can run following script:

```shell
for ii in $(terraform state list | grep "istio_appgateway\[0\]"); do
  terraform state mv ${ii} $(echo ${ii} | sed 's/istio_appgateway\[0\]/istio_appgateway/');
done
```
