defmodule ExAzureKeyVault.Client do
  @moduledoc """
  Client for creating or getting Azure Key Vault.
  """
  alias __MODULE__
  alias ExAzureKeyVault.APIVersion
  alias ExAzureKeyVault.Auth
  alias ExAzureKeyVault.Url

  @enforce_keys [:api_version, :bearer_token, :vault_name]
  defstruct(
    api_version: nil,
    bearer_token: nil,
    vault_name: nil
  )

  @type t :: %__MODULE__{
    api_version: String.t,
    bearer_token: String.t,
    vault_name: String.t
  }

  @doc """
  Creates `%ExAzureKeyVault.Client{}` struct with connection information.

  ## Examples

  Using default API version.

      iex> ExAzureKeyVault.Client.new("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", "my-vault")
      %ExAzureKeyVault.Client{
        api_version: "2016-10-01",
        bearer_token: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        vault_name: "my-vault"
      }

  Passing custom API version.

      iex> ExAzureKeyVault.Client.new("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", "my-vault", "2015-06-01")
      %ExAzureKeyVault.Client{
        api_version: "2015-06-01",
        bearer_token: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        vault_name: "my-vault"
      }

  """
  @spec new(String.t, String.t, String.t | nil) :: Client.t
  def new(bearer_token, vault_name, api_version \\ nil) do
    %Client{
      api_version: api_version || APIVersion.version(),
      bearer_token: bearer_token,
      vault_name: vault_name
    }
  end

  @doc """
  Connects to Azure Key Vault.

  ## Examples

  When defining environment variables and/or adding to configuration.

      $ export AZURE_CLIENT_ID="14e79d90-9abf..."
      $ export AZURE_CLIENT_SECRET="14e7a11e-9abf..."
      $ export AZURE_TENANT_ID="14e7a376-9abf..."
      $ export AZURE_VAULT_NAME="my-vault"

      # Config.exs
      config :ex_azure_key_vault,
        azure_client_id: {:system, "AZURE_CLIENT_ID"},
        azure_client_secret: {:system, "AZURE_CLIENT_SECRET"},
        azure_tenant_id: {:system, "AZURE_TENANT_ID"},
        azure_vault_name: {:system, "AZURE_VAULT_NAME"}

      iex> ExAzureKeyVault.Client.connect()
      %ExAzureKeyVault.Client{
        api_version: "2016-10-01",
        bearer_token: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        vault_name: "my-vault"
      }

  Passing custom parameters.

      iex> ExAzureKeyVault.Client.connect("my-vault", "14e7a376-9abf...", "14e79d90-9abf...", "14e7a11e-9abf...")
      %ExAzureKeyVault.Client{
        api_version: "2016-10-01",
        bearer_token: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        vault_name: "my-vault"
      }

  """
  @spec connect() :: Client.t | {:error, any}
  @spec connect(String.t | nil, String.t | nil, String.t | nil, String.t | nil) :: Client.t | {:error, any}
  def connect(vault_name \\ nil, tenant_id \\ nil, client_id \\ nil, client_secret \\ nil) do
    vault_name = get_env(:azure_vault_name, vault_name)
    tenant_id = get_env(:azure_tenant_id, tenant_id)
    client_id = get_env(:azure_client_id, client_id)
    client_secret = get_env(:azure_client_secret, client_secret)
    if is_empty(vault_name), do: raise ArgumentError, message: "Vault name is not present"
    if is_empty(tenant_id), do: raise ArgumentError, message: "Tenant ID is not present"
    if is_empty(client_id), do: raise ArgumentError, message: "Client ID is not present"
    if is_empty(client_secret), do: raise ArgumentError, message: "Client secret is not present"
    with %Auth{} = auth <- Auth.new(client_id, client_secret, tenant_id),
         {:ok, bearer_token} <- auth |> Auth.get_bearer_token,
         %Client{} = client <- bearer_token |> Client.new(vault_name, APIVersion.version()) do
      client
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns secret value.

  ## Examples

  Ignoring secret version.

      iex> ExAzureKeyVault.Client.get_secret(
      %ExAzureKeyVault.Client{
        api_version: "2016-10-01",
        bearer_token: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        vault_name: "my-vault"
      }, "my-secret")
      {:ok, "my-value"}

  Passing secret version.

      iex> ExAzureKeyVault.Client.get_secret(
      %ExAzureKeyVault.Client{
        api_version: "2016-10-01",
        bearer_token: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        vault_name: "my-vault",
      }, "my-secret", "03b424a49ac3...")
      {:ok, "my-other-value"}

  """
  @spec get_secret(Client.t, String.t, String.t | nil) :: {:ok, String.t} | {:error, any}
  def get_secret(%Client{} = params, secret_name, secret_version \\ nil) do
    url = Url.new(secret_name, params.vault_name) |> Url.get_url(secret_version, params.api_version)
    headers = ["Authorization": params.bearer_token, "Content-Type": "application/json; charset=utf-8"]
    options = [ssl: [{:versions, [:'tlsv1.2']}]]
    case HTTPoison.get(url, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.decode!(body)
        {:ok, response["value"]}
      {:ok, %HTTPoison.Response{status_code: 404, body: body}} ->
        response = Poison.decode!(body)
        {:error, response}
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        if status
          |> Integer.to_string()
          |> String.starts_with?("4") do
          if body != "" do
            response = Poison.decode!(body)
            {:error, response}
          else
            {:error, "Error: #{status}: #{url}"}
          end
        end
      {:error, %HTTPoison.Error{reason: reason}} ->
        if reason == :nxdomain do
          {:error, "Error: Couldn't resolve host name #{url}"}
        else
          {:error, reason}
        end
      _ ->
        {:error, "Something went wrong"}
    end
  end

  @doc """
  Creates a new secret.

  ## Examples

      iex> ExAzureKeyVault.Client.create_secret(
      %ExAzureKeyVault.Client{
        api_version: "2016-10-01",
        bearer_token: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        vault_name: "my-vault"
      }, "my-new-secret", "my-new-value")
      :ok

  """
  @spec create_secret(Client.t, String.t, String.t) :: :ok | {:error, any}
  def create_secret(%Client{} = params, secret_name, secret_value) do
    url = Url.new(secret_name, params.vault_name) |> Url.get_url(params.api_version)
    body = Url.get_body(secret_value)
    headers = ["Authorization": params.bearer_token, "Content-Type": "application/json; charset=utf-8"]
    options = [ssl: [{:versions, [:'tlsv1.2']}]]
    case HTTPoison.put(url, body, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        :ok
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        if status
          |> Integer.to_string()
          |> String.starts_with?("4") do
          if body != "" do
            response = Poison.decode!(body)
            {:error, response}
          else
            {:error, "Error: #{status}: #{url}"}
          end
        end
      {:error, %HTTPoison.Error{reason: reason}} ->
        if reason == :nxdomain do
          {:error, "Error: Couldn't resolve host name #{url}"}
        else
          {:error, reason}
        end
      _ ->
        {:error, "Something went wrong"}
    end
  end

  @spec get_env(atom, String.t) :: String.t
  defp get_env(key, default) do
    default || Application.get_env(:ex_azure_key_vault, key) |> return_value()
  end

  @spec return_value(tuple) :: String.t
  defp return_value({:system, key}) when is_binary(key) do
    System.get_env(key)
  end

  @spec return_value(String.t) :: String.t
  defp return_value(value), do: value

  @spec is_empty(String.t) :: boolean
  defp is_empty(string) do
    is_nil(string) || String.trim(string) == ""
  end
end
