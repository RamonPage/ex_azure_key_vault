defmodule ExAzureKeyVault.HTTPUtils do
  @moduledoc """
  Internal module for returning HTTP utilities.
  """

  @doc """
  Returns the "application/x-www-form-urlencoded" header.

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
  @spec headers_authorization(String.t) :: list
  def headers_authorization(bearer_token) do
    ["Authorization": bearer_token, "Content-Type": "application/json; charset=utf-8"]
  end

  @doc """
  Returns ssl options.

  ## Examples

      iex(1)> ExAzureKeyVault.HTTPUtils.options_ssl()
      [ssl: [{:versions, [:'tlsv1.2']}]]

  """
  @spec options_ssl :: list
  def options_ssl do
    [ssl: [{:versions, [:'tlsv1.2']}]]
  end
end