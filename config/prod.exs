use Mix.Config

config :ex_azure_key_vault,
  azure_client_id: {:system, "AZURE_CLIENT_ID"},
  azure_client_secret: {:system, "AZURE_CLIENT_SECRET"},
  azure_tenant_id: {:system, "AZURE_TENANT_ID"},
  azure_vault_name: {:system, "AZURE_VAULT_NAME"},
  azure_cert_base64_thumbprint: {:system, "AZURE_CERT_BASE64_THUMBPRINT"},
  azure_cert_private_key_pem: {:system, "AZURE_CERT_PRIVATE_KEY_PEM"}
