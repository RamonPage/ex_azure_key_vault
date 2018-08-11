defmodule ExAzureKeyVault.APIVersion do
  @moduledoc """
  Internal module for returning the Azure Key Vault API Version.
  """

  @doc """
  Returns the Azure Key Vault API Version.

  ## Examples

      iex> ExAzureKeyVault.APIVersion.version()
      "2016-10-01"

  """
  @spec version :: String.t
  def version do
    "2016-10-01"
  end
end