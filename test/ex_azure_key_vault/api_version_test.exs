defmodule ExAzureKeyVault.APIVersionTest do
  use ExUnit.Case
  doctest ExAzureKeyVault.APIVersion

  test "shows the api version" do
    assert ExAzureKeyVault.APIVersion.version() == "7.3"
  end
end
