defmodule ExAzureKeyVault.ManagedIdentityAuth do
  @moduledoc """
  Internal module for getting authentication token for Azure connection.
  """
  alias __MODULE__
  alias ExAzureKeyVault.HTTPUtils

  @enforce_keys [:endpoint, :header]
  defstruct(
    endpoint: nil,
    header: nil
  )

  @type t :: %__MODULE__{
          endpoint: String.t(),
          header: String.t()
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
  @spec new(String.t(), String.t()) :: ManagedIdentityAuth.t()
  def new(endpoint, header) do
    %ManagedIdentityAuth{endpoint: endpoint, header: header}
  end

  @spec new() :: ManagedIdentityAuth.t()
  def new() do
    endpoint = System.get_env("IDENTITY_ENDPOINT")
    header = System.get_env("IDENTITY_HEADER")
    ManagedIdentityAuth.new(endpoint, header)
  end

  @doc """
  Returns bearer token for Azure connection.

  ## Examples

      iex(1)> ExAzureKeyVault.ManagedIdentityAuth.new("endpoint", "header")
      ...(1)> |> ExAzureKeyVault.ManagedIdentityAuth.get_bearer_token()
      {:ok, "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}

  """
  @spec get_bearer_token(ManagedIdentityAuth.t()) :: {:ok, String.t()} | {:error, any}
  def get_bearer_token(%ManagedIdentityAuth{} = params) do
    endpoint = params.endpoint
    header = params.header
    apiVersion = "2019-08-01"
    resource = "https://vault.azure.net"
    headers = ["X-Identity-Header": header]
    url = "#{endpoint}?api-version=#{apiVersion}&resource=#{resource}"
    options = HTTPUtils.options_ssl()

    case HTTPoison.get(url, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Jason.decode!(body)
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
end
