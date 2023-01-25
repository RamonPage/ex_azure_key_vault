defmodule ExAzureKeyVault.APIVersion do
  @moduledoc """
  Internal module for returning the Azure Key Vault API Version.
  """

  @doc """
  Returns the Azure Key Vault API Version.

  ## Examples

      iex(1)> ExAzureKeyVault.APIVersion.version()
      "7.3"

  """
  @spec version :: String.t()
  def version do
    "7.3"
  end
end
