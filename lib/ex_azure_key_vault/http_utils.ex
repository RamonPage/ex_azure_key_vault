defmodule ExAzureKeyVault.HTTPUtils do
  @moduledoc """
  Internal module for returning HTTP utilities.
  """

  @doc """
  Returns "application/x-www-form-urlencoded" header.

  ## Examples

      iex(1)> ExAzureKeyVault.HTTPUtils.headers_form_urlencoded()
      ["Content-Type": "application/x-www-form-urlencoded"]

  """
  @spec headers_form_urlencoded :: list
  def headers_form_urlencoded do
    ["Content-Type": "application/x-www-form-urlencoded"]
  end

  @doc """
  Returns authorization header.

  ## Examples

      iex(1)> ExAzureKeyVault.HTTPUtils.headers_authorization("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
      ["Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", "Content-Type": "application/json; charset=utf-8"]

  """
  @spec headers_authorization(String.t()) :: list
  def headers_authorization(bearer_token) do
    [Authorization: bearer_token, "Content-Type": "application/json; charset=utf-8"]
  end

  @doc """
  Returns ssl options.

  ## Examples

      iex(1)> ExAzureKeyVault.HTTPUtils.options_ssl()
      [ssl: [{:versions, [:'tlsv1.2']}]]

  """
  @spec options_ssl :: list
  def options_ssl do
    [ssl: [{:versions, [:"tlsv1.2"]}]]
  end

  @doc """
  Returns ok response.

  ## Examples

      iex(1)> ExAzureKeyVault.HTTPUtils.response_ok("{}")
      {:ok, %{}}

  """
  @spec response_ok(String.t()) :: {:ok, any}
  def response_ok(body) do
    response = Jason.decode!(body)
    {:ok, response}
  end

  @doc """
  Returns basic error message for 4xx status codes.

  ## Examples

      iex(1)> ExAzureKeyVault.HTTPUtils.response_client_error(401, "https://wrong-vault.vault.azure.net/secrets")
      {:error, "Error: 401: https://wrong-vault.vault.azure.net/secrets"}

  """
  @spec response_client_error(integer, String.t()) :: {:error, String.t()} | nil
  def response_client_error(status, url) do
    if is_client_error(status) do
      {:error, "Error: #{status}: #{url}"}
    end
  end

  @doc """
  Returns error message for 4xx status codes.

  ## Examples

      iex(1)> ExAzureKeyVault.HTTPUtils.response_client_error(404, "", "{\\"error_message\\":\\"Not found\\"}")
      {:error, %{"error_message" => "Not found"}}

  """
  @spec response_client_error(integer, String.t(), String.t()) :: {:error, any} | nil
  def response_client_error(status, _url, body) do
    if is_client_error(status) do
      response = Jason.decode!(body)
      {:error, response}
    end
  end

  @doc """
  Returns basic error or :ok response.

  ## Examples

  When is a client error.

      iex(1)> ExAzureKeyVault.HTTPUtils.response_client_error_or_ok(401, "https://wrong-vault.vault.azure.net/secrets")
      {:error, "Error: 401: https://wrong-vault.vault.azure.net/secrets"}

  When is a redirection.

      iex(1)> ExAzureKeyVault.HTTPUtils.response_client_error_or_ok(301, "https://wrong-vault.vault.azure.net/secrets")
      :ok

  """
  @spec response_client_error_or_ok(integer, String.t()) :: {:error, String.t()} | :ok
  def response_client_error_or_ok(status, url) do
    response_client_error(status, url) || :ok
  end

  @doc """
  Returns client error or :ok response.

  ## Examples

  When is a client error.

      iex(1)> ExAzureKeyVault.HTTPUtils.response_client_error_or_ok(404, "", "{\\"error_message\\":\\"Not found\\"}")
      {:error, %{"error_message" => "Not found"}}

  When is a redirection.

      iex(1)> ExAzureKeyVault.HTTPUtils.response_client_error_or_ok(301, "", "{}")
      {:ok, %{}}

  """
  @spec response_client_error_or_ok(integer, String.t(), String.t()) ::
          {:error, String.t()} | {:ok, String.t()}
  def response_client_error_or_ok(status, url, body) do
    response_client_error(status, url, body) || response_ok(body)
  end

  @doc """
  Returns error message for :nxdomain error.

  ## Examples

      iex(1)> ExAzureKeyVault.HTTPUtils.response_server_error(:nxdomain, "https://wrong-vault.vault.azure.net/secrets")
      {:error, "Error: Couldn't resolve host name https://wrong-vault.vault.azure.net/secrets"}

  """
  @spec response_server_error(atom, String.t()) :: {:error, String.t()}
  def response_server_error(:nxdomain, url) do
    {:error, "Error: Couldn't resolve host name #{url}"}
  end

  @doc """
  Returns error message for server errors.

  ## Examples

      iex(1)> ExAzureKeyVault.HTTPUtils.response_server_error(:econnrefused)
      {:error, :econnrefused}

  """
  @spec response_server_error(atom) :: {:error, any}
  def response_server_error(reason) do
    {:error, reason}
  end

  @spec is_client_error(integer) :: boolean
  defp is_client_error(status) do
    status
    |> Integer.to_string()
    |> String.starts_with?("4")
  end
end
