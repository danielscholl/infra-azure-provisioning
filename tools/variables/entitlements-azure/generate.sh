

cat > local.yaml <<LOCALRUN
AZURE_TENANT_ID: "${TENANT_ID}"
AZURE_CLIENT_ID: "${ENV_PRINCIPAL_ID}"
AZURE_CLIENT_SECRET: "${ENV_PRINCIPAL_SECRET}"
azure_activedirectory_session_stateless: "true"
azure_activedirectory_AppIdUri: "api://${ENV_APP_ID}"
aad_client_id: "${ENV_APP_ID}"
appinsights_key: "${ENV_APPINSIGHTS_KEY}"
KEYVAULT_URI: "${ENV_KEYVAULT}"
cosmosdb_database: "${COSMOS_DB_NAME}"
spring_application_name: "entitlements-azure"
service_domain_name: "${COMPANY_DOMAIN}"
server_port: "8080"
LOCALRUN

cat > test/local.yaml <<LOCALTEST
ENTITLEMENT_URL: "http://localhost:${server_port}/entitlements/v1/"
MY_TENANT: "${OSDU_TENANT}"
AZURE_AD_TENANT_ID: "${TENANT_ID}"
INTEGRATION_TESTER: "${ENV_PRINCIPAL_ID}"
ENTITLEMENT_MEMBER_NAME_VALID: "${ENV_PRINCIPAL_ID}"
AZURE_TESTER_SERVICEPRINCIPAL_SECRET: "${ENV_PRINCIPAL_SECRET}"
AZURE_AD_APP_RESOURCE_ID: "${ENV_APP_ID}"
AZURE_AD_OTHER_APP_RESOURCE_ID: "${OTHER_APP_ID}"
AZURE_AD_OTHER_APP_RESOURCE_OID: "${OTHER_APP_OID}"
DOMAIN: "${COMPANY_DOMAIN}"
EXPIRED_TOKEN: "${INVALID_JWT}"
AZURE_AD_USER_EMAIL: "${AD_USER_EMAIL}"
AZURE_AD_USER_OID: "${AD_USER_OID}"
AZURE_AD_GUEST_EMAIL: "${AD_GUEST_EMAIL}"
AZURE_AD_GUEST_OID: "${AD_GUEST_OID}"
ENTITLEMENT_GROUP_NAME_VALID: "integ.test.data.creator"
ENTITLEMENT_MEMBER_NAME_INVALID: "InvalidTestAdmin"
LOCALTEST

cat > test/hosted.yaml <<DEVTEST
ENTITLEMENT_URL: "https://${ENV_HOST}/entitlements/v1/"         # Test Against Environment
MY_TENANT: "${OSDU_TENANT}"
AZURE_AD_TENANT_ID: "${TENANT_ID}"
INTEGRATION_TESTER: "${ENV_PRINCIPAL_ID}"
ENTITLEMENT_MEMBER_NAME_VALID: "${ENV_PRINCIPAL_ID}"
AZURE_TESTER_SERVICEPRINCIPAL_SECRET: "${ENV_PRINCIPAL_SECRET}"
AZURE_AD_APP_RESOURCE_ID: "${ENV_APP_ID}"
AZURE_AD_OTHER_APP_RESOURCE_ID: "${OTHER_APP_ID}"
AZURE_AD_OTHER_APP_RESOURCE_OID: "${OTHER_APP_OID}"
DOMAIN: "${COMPANY_DOMAIN}"
EXPIRED_TOKEN: "${INVALID_JWT}"
AZURE_AD_USER_EMAIL: "${AD_USER_EMAIL}"
AZURE_AD_USER_OID: "${AD_USER_OID}"
AZURE_AD_GUEST_EMAIL: "${AD_GUEST_EMAIL}"
AZURE_AD_GUEST_OID: "${AD_GUEST_OID}"
ENTITLEMENT_GROUP_NAME_VALID: "integ.test.data.creator"
ENTITLEMENT_MEMBER_NAME_INVALID: "InvalidTestAdmin"
DEVTEST