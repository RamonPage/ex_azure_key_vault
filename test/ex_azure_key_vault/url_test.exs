defmodule ExAzureKeyVault.UrlTest do
  use ExUnit.Case
  doctest ExAzureKeyVault.Url

  setup do
    %{url: ExAzureKeyVault.Url.new("my-secret", "my-vault")}
  end

  describe "when passing secret version" do
    test "gets secret url", context do
      url = context[:url] |> ExAzureKeyVault.Url.get_url("7ea98ee699b1", "2016-10-01")

      assert url ==
               "https://my-vault.vault.azure.net/secrets/my-secret/7ea98ee699b1?api-version=2016-10-01"
    end
  end

  describe "when secret version is nil" do
    test "gets secret url", context do
      url = context[:url] |> ExAzureKeyVault.Url.get_url(nil, "2016-10-01")
      assert url == "https://my-vault.vault.azure.net/secrets/my-secret?api-version=2016-10-01"
    end
  end

  describe "when secret version is not passed" do
    test "gets secret url", context do
      url = context[:url] |> ExAzureKeyVault.Url.get_url("2016-10-01")
      assert url == "https://my-vault.vault.azure.net/secrets/my-secret?api-version=2016-10-01"
    end
  end
end
