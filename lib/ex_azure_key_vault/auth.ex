defmodule ExAzureKeyVault.Auth do
  @moduledoc """
  Internal module for getting authentication token for Azure connection.
  """
  alias __MODULE__
  alias ExAzureKeyVault.HTTPUtils

  @enforce_keys [:client_id, :client_secret, :tenant_id]
  defstruct(
    client_id: nil,
    client_secret: nil,
    tenant_id: nil
  )

  @type t :: %__MODULE__{
          client_id: String.t(),
          client_secret: String.t(),
          tenant_id: String.t()
        }

  @doc """
  Creates `%ExAzureKeyVault.Auth{}` struct with account tokens.

  ## Examples

      iex(1)> ExAzureKeyVault.Auth.new("6f185f82-9909...", "6f1861e4-9909...", "6f185bb8-9909...")
      %ExAzureKeyVault.Auth{
        client_id: "6f185f82-9909...",
        client_secret: "6f1861e4-9909...",
        tenant_id: "6f185bb8-9909..."
      }

  """
  @spec new(String.t(), String.t(), String.t()) :: Auth.t()
  def new(client_id, client_secret, tenant_id) do
    %Auth{client_id: client_id, client_secret: client_secret, tenant_id: tenant_id}
  end

  @doc """
  Returns bearer token for Azure connection.

  ## Examples

      iex(1)> ExAzureKeyVault.Auth.new("6f185f82-9909...", "6f1861e4-9909...", "6f185bb8-9909...")
      ...(1)> |> ExAzureKeyVault.Auth.get_bearer_token()
      {:ok, "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}

  """
  @spec get_bearer_token(Auth.t()) :: {:ok, String.t()} | {:error, any}
  def get_bearer_token(%Auth{} = params) do
    url = auth_url(params.tenant_id)
    body = auth_body(params.client_id, params.client_secret)
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
    "https://login.windows.net/#{tenant_id}/oauth2/token"
  end

  @spec auth_body(String.t(), String.t()) :: tuple
  defp auth_body(client_id, client_secret) do
    {:form,
     [
       grant_type: "client_credentials",
       client_id: client_id,
       client_secret: client_secret,
       resource: "https://vault.azure.net"
     ]}
  end
end
