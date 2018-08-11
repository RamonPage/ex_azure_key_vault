defmodule ExAzureKeyVault.APIVersionTest do
  use ExUnit.Case
  doctest ExAzureKeyVault.APIVersion

  test "shows the api version" do
    assert ExAzureKeyVault.APIVersion.version() == "2016-10-01"
  end
end
