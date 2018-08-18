defmodule ExAzureKeyVault.Url do
  @moduledoc """
  Internal module for getting Azure Key Vault URL.
  """
  alias __MODULE__

  @enforce_keys [:secret_name, :vault_name]
  defstruct(
    secret_name: nil,
    vault_name: nil
  )
  @type t :: %__MODULE__{
    secret_name: String.t,
    vault_name: String.t
  }

  @doc """
  Creates `%ExAzureKeyVault.Url{}` struct with vault name.

  ## Examples

      iex> ExAzureKeyVault.Url.new("my-secret", "my-vault")
      %ExAzureKeyVault.Url{secret_name: "my-secret", vault_name: "my-vault"}

  """
  @spec new(String.t, String.t) :: Url.t
  def new(secret_name, vault_name) do
    %Url{secret_name: secret_name, vault_name: vault_name}
  end

  @doc """
  Returns Azure Key Vault URL for secret management.

  ## Examples

  Passing secret version.

      iex> ExAzureKeyVault.Url.get_url(%ExAzureKeyVault.Url{secret_name: "my-secret", vault_name: "my-vault"}, "7ea98ee699b1...", "2016-10-01")
      "https://my-vault.vault.azure.net/secrets/my-secret/7ea98ee699b1...?api-version=2016-10-01"

  Ignoring secret version.

      iex> ExAzureKeyVault.Url.get_url(%ExAzureKeyVault.Url{secret_name: "my-secret", vault_name: "my-vault"}, nil, "2016-10-01")
      "https://my-vault.vault.azure.net/secrets/my-secret?api-version=2016-10-01"

  """
  @spec get_url(Url.t, String.t | nil, String.t) :: String.t
  def get_url(%Url{} = params, version \\ nil, api_version) do
    base_url = base_secret_url(params.vault_name, params.secret_name)
    api_version_string = get_api_version_string(api_version)
    if !is_nil(version) && version != "" do
      base_url <> "/#{version}" <> api_version_string
    else
      base_url <> api_version_string
    end
  end

  @spec get_secrets_url(Url.t, integer | nil, String.t) :: String.t
  def get_secrets_url(%Url{} = params, max_results \\ nil, api_version) do
    base_url = base_secrets_url(params.vault_name)
    api_version_string = get_api_version_string(api_version)
    if !is_nil(max_results) && max_results != "" do
      base_url <> api_version_string <> "&maxresults=#{max_results}"
    else
      base_url <> api_version_string
    end
  end

  @doc """
  Returns body for secret creation.

  ## Examples

      iex> ExAzureKeyVault.Url.get_body("my-secret")
      "{\\"value\\":\\"my-secret\\"}"

  """
  @spec get_body(String.t) :: String.t
  def get_body(secret_value) do
    Poison.encode!(%{value: secret_value})
  end

  @spec base_secret_url(String.t, String.t) :: String.t
  defp base_secret_url(vault_name, secret_name) do
    "https://#{vault_name}.vault.azure.net/secrets/#{secret_name}"
  end

  @spec base_secrets_url(String.t) :: String.t
  defp base_secrets_url(vault_name) do
    "https://#{vault_name}.vault.azure.net/secrets"
  end

  @spec get_api_version_string(String.t) :: String.t
  defp get_api_version_string(api_version) do
    "?api-version=#{api_version}"
  end
end