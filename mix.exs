defmodule ExAzureKeyVault.MixProject do
  use Mix.Project

  @version "0.0.1"
  @github_url "https://github.com/RamonPage/ex_azure_key_vault"

  def project do
    [
      app: :ex_azure_key_vault,
      name: "ex_azure_key_vault",
      source_url: @github_url,
      version: @version,
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :httpoison]
    ]
  end

  defp description do
    """
    Elixir wrapper for Azure Key Vault REST API
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "CHANGELOG*", "README*", "LICENSE*"],
      maintainers: ["Ramon Bispo"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: ["README.md"]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.2.0"},
      {:poison, "~> 4.0.0"},
      {:ex_doc, "~> 0.19.0", only: :dev, runtime: false},
      {:mock, "~> 0.3.2", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      build: ["compile --force", "docs"]
    ]
  end
end
