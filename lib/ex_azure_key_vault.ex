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

      iex(1)> ExAzureKeyVault.Client.new("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", "my-vault")
      %ExAzureKeyVault.Client{
        api_version: "2016-10-01",
        bearer_token: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        vault_name: "my-vault"
      }

  Passing custom API version.

      iex(1)> ExAzureKeyVault.Client.new("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", "my-vault", "2015-06-01")
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

      iex(1)> ExAzureKeyVault.Client.connect()
      %ExAzureKeyVault.Client{
        api_version: "2016-10-01",
        bearer_token: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        vault_name: "my-vault"
      }

  Passing custom parameters.

      iex(1)> ExAzureKeyVault.Client.connect("custom-vault", "14e7a376-9abf...", "14e79d90-9abf...", "14e7a11e-9abf...")
      %ExAzureKeyVault.Client{
        api_version: "2016-10-01",
        bearer_token: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        vault_name: "custom-vault"
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

      iex(1)> ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secret("my-secret")
      {:ok, "my-value"}

  Passing secret version.

      iex(1)> ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secret("my-secret", "03b424a49ac3...")
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
  Returns list of secrets.

  ## Examples

  Passing a maximum number of 2 results in a page.

      iex(1)> ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets(2)
      {:ok,
        %{
          "nextLink" => "https://my-vault.vault.azure.net:443/secrets?api-version=2016-10-01&$skiptoken=eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6...&maxresults=2",
          "value" => [
            %{
              "attributes" => %{
                "created" => 1533704004,
                "enabled" => true,
                "recoveryLevel" => "Purgeable",
                "updated" => 1533704004
              },
              "id" => "https://my-vault.vault.azure.net/secrets/my-secret"
            },
            %{
              "attributes" => %{
                "created" => 1532633078,
                "enabled" => true,
                "recoveryLevel" => "Purgeable",
                "updated" => 1532633078
              },
              "id" => "https://my-vault.vault.azure.net/secrets/another-secret"
            }
          ]
        }}

  Ignoring maximum number of results.

      iex(1)> ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets()
      {:ok,
        %{
          "nextLink" => nil,
          "value" => [
            %{
              "attributes" => %{
                "created" => 1533704004,
                "enabled" => true,
                "recoveryLevel" => "Purgeable",
                "updated" => 1533704004
              },
              "id" => "https://my-vault.vault.azure.net/secrets/my-secret"
            },
            %{
              "attributes" => %{
                "created" => 1532633078,
                "enabled" => true,
                "recoveryLevel" => "Purgeable",
                "updated" => 1532633078
              },
              "id" => "https://my-vault.vault.azure.net/secrets/another-secret"
            },
            %{
              "attributes" => %{
                "created" => 1532633078,
                "enabled" => true,
                "recoveryLevel" => "Purgeable",
                "updated" => 1532633078
              },
              "id" => "https://my-vault.vault.azure.net/secrets/test-secret"
            }
          ]
        }}
  """
  @spec get_secrets(Client.t, integer | nil) :: {:ok, String.t} | {:error, any}
  def get_secrets(%Client{} = params, max_results \\ nil) do
    url = Url.new(nil, params.vault_name) |> Url.get_secrets_url(max_results, params.api_version)
    headers = ["Authorization": params.bearer_token, "Content-Type": "application/json; charset=utf-8"]
    options = [ssl: [{:versions, [:'tlsv1.2']}]]
    case HTTPoison.get(url, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.decode!(body)
        {:ok, response}
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
  Returns next page of secrets in the pagination.

  ## Examples

      iex(1)> client = ExAzureKeyVault.Client.connect()
      ...
      iex(1)> {_, secrets} = client |> ExAzureKeyVault.Client.get_secrets(2)
      ...
      iex(1)> {_, next_secrets} = client |> ExAzureKeyVault.Client.get_secrets_next(secrets["nextLink"])
      {:ok,
        %{
          "nextLink" => nil,
          "value" => [
            %{
              "attributes" => %{
                "created" => 1532633078,
                "enabled" => true,
                "recoveryLevel" => "Purgeable",
                "updated" => 1532633078
              },
              "id" => "https://my-vault.vault.azure.net/secrets/test-secret"
            }
          ]
        }}
  """
  @spec get_secrets_next(Client.t, String.t) :: {:ok, String.t} | {:error, any}
  def get_secrets_next(%Client{} = params, next_link) do
    if is_empty(next_link), do: raise ArgumentError, message: "Next link is not present"
    unless next_link
      |> String.starts_with?("https://#{params.vault_name}.vault.azure.net") do
      raise ArgumentError, message: "Next link #{next_link} is not valid"
    end
    headers = ["Authorization": params.bearer_token, "Content-Type": "application/json; charset=utf-8"]
    options = [ssl: [{:versions, [:'tlsv1.2']}]]
    case HTTPoison.get(next_link, headers, options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.decode!(body)
        {:ok, response}
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        if status
          |> Integer.to_string()
          |> String.starts_with?("4") do
          if body != "" do
            response = Poison.decode!(body)
            {:error, response}
          else
            {:error, "Error: #{status}: #{next_link}"}
          end
        end
      {:error, %HTTPoison.Error{reason: reason}} ->
        if reason == :nxdomain do
          {:error, "Error: Couldn't resolve host name #{next_link}"}
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

      iex(1)> ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.create_secret("my-new-secret", "my-new-value")
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
