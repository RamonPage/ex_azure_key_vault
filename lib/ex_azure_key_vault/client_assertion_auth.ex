defmodule ExAzureKeyVault.ClientAssertionAuth do
  @moduledoc """
  Internal module for getting authentication token for Azure connection using client assertion.
  """
  alias __MODULE__
  alias ExAzureKeyVault.HTTPUtils

  @enforce_keys [:client_id, :tenant_id, :cert_base64_thumbprint, :cert_private_key_pem]
  defstruct(
    client_id: nil,
    tenant_id: nil,
    cert_base64_thumbprint: nil,
    cert_private_key_pem: nil
  )

  @type t :: %__MODULE__{
          client_id: String.t(),
          tenant_id: String.t(),
          cert_base64_thumbprint: String.t(),
          cert_private_key_pem: String.t()
        }

  @doc ~S"""
  Creates `%ExAzureKeyVault.ClientAssertionAuth{}` struct with account tokens and cert data.

  ## Examples

      iex(1)> ExAzureKeyVault.ClientAssertionAuth.new("6f185f82-9909...", "6f1861e4-9909...", "Dss7v2YI3GgCGfl...", "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEF...")
      %ExAzureKeyVault.ClientAssertionAuth{
        client_id: "6f185f82-9909...",
        tenant_id: "6f1861e4-9909...",
        cert_base64_thumbprint: "Dss7v2YI3GgCGfl...",
        cert_private_key_pem: "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEF..."
      }

  """
  @spec new(String.t(), String.t(), String.t(), String.t()) :: ClientAssertionAuth.t()
  def new(client_id, tenant_id, cert_base64_thumbprint, cert_private_key_pem) do
    %ClientAssertionAuth{
      client_id: client_id,
      tenant_id: tenant_id,
      cert_base64_thumbprint: cert_base64_thumbprint,
      cert_private_key_pem: cert_private_key_pem
    }
  end

  @doc ~S"""
  Returns bearer token for Azure connection using client assertion.

  ## Examples

      iex(1)> ExAzureKeyVault.ClientAssertionAuth.new("6f185f82-9909...", "6f1861e4-9909...", "Dss7v2YI3GgCGfl...", "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEF...")
      ...(1)> |> ExAzureKeyVault.ClientAssertionAuth.get_bearer_token()
      {:ok, "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}

  """
  @spec get_bearer_token(ClientAssertionAuth.t()) :: {:ok, String.t()} | {:error, any}
  def get_bearer_token(%ClientAssertionAuth{} = params) do
    client_assertion =
      auth_client_assertion(
        params.client_id,
        params.tenant_id,
        params.cert_base64_thumbprint,
        params.cert_private_key_pem
      )

    url = auth_url(params.tenant_id)
    body = auth_body(params.client_id, client_assertion)
    headers = HTTPUtils.headers_form_urlencoded()
    options = HTTPUtils.options_ssl()

    case HTTPoison.post(url, body, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.decode!(body)
        {:ok, "Bearer #{response["access_token"]}"}

      {:ok, %HTTPoison.Response{status_code: status, body: ""}} ->
        HTTPUtils.response_client_error_or_ok(status, url)

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        HTTPUtils.response_client_error_or_ok(status, url, body)

      {:error, %HTTPoison.Error{reason: :nxdomain}} ->
        HTTPUtils.response_server_error(:nxdomain, url)

      {:error, %HTTPoison.Error{reason: reason}} ->
        HTTPUtils.response_server_error(reason)

      _ ->
        {:error, "Something went wrong"}
    end
  end

  @spec auth_url(String.t()) :: String.t()
  defp auth_url(tenant_id) do
    "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token"
  end

  @spec auth_body(String.t(), String.t()) :: tuple
  defp auth_body(client_id, client_assertion) do
    {:form,
     [
       grant_type: "client_credentials",
       client_id: client_id,
       client_assertion: client_assertion,
       client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
       scope: "https://vault.azure.net/.default"
     ]}
  end

  @spec auth_client_assertion(String.t(), String.t(), String.t(), String.t()) :: String.t()
  defp auth_client_assertion(client_id, tenant_id, cert_base64_thumbprint, cert_private_key_pem) do
    signer =
      Joken.Signer.create("RS256", %{"pem" => cert_private_key_pem}, %{
        "x5t" => cert_base64_thumbprint
      })

    sub = client_id
    iss = client_id
    jti = Joken.generate_jti()
    nbf = Joken.current_time()
    # in 1 minute
    exp = Joken.current_time() + 60
    aud = auth_url(tenant_id)

    {:ok, claims} =
      Joken.generate_claims(%{}, %{sub: sub, iss: iss, jti: jti, nbf: nbf, exp: exp, aud: aud})

    {:ok, jwt, _} = Joken.encode_and_sign(claims, signer)
    jwt
  end
end
