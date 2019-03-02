# Elixir Azure Key Vault

[![Build Status](https://api.travis-ci.org/RamonPage/ex_azure_key_vault.svg?branch=master)](https://travis-ci.org/RamonPage/ex_azure_key_vault)
[![Hex.pm Version](https://img.shields.io/hexpm/v/ex_azure_key_vault.svg)](https://hex.pm/packages/ex_azure_key_vault)
[![Hex.pm Download Total](https://img.shields.io/hexpm/dt/ex_azure_key_vault.svg)](https://hex.pm/packages/ex_azure_key_vault)
[![Coverage Status](https://coveralls.io/repos/github/RamonPage/ex_azure_key_vault/badge.svg?branch=master)](https://coveralls.io/github/RamonPage/ex_azure_key_vault?branch=master)

Elixir wrapper for Azure Key Vault REST API.

## Installation

The package can be installed
by adding `ex_azure_key_vault` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_azure_key_vault, "~> 0.2.1"}
  ]
end
```

[Documentation is available on hexdocs.pm](https://hexdocs.pm/ex_azure_key_vault/).

## Basic usage

When defining environment variables and/or adding to configuration.

```bash
$ export AZURE_CLIENT_ID="14e79d90-9abf..."
$ export AZURE_CLIENT_SECRET="14e7a11e-9abf..."
$ export AZURE_TENANT_ID="14e7a376-9abf..."
$ export AZURE_VAULT_NAME="my-vault"
```

```elixir
# Config.exs
config :ex_azure_key_vault,
  azure_client_id: {:system, "AZURE_CLIENT_ID"},
  azure_client_secret: {:system, "AZURE_CLIENT_SECRET"},
  azure_tenant_id: {:system, "AZURE_TENANT_ID"},
  azure_vault_name: {:system, "AZURE_VAULT_NAME"}
```

### Getting a secret
```elixir
iex(1)> ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secret("my-secret")
{:ok, "my-value"}
```

### Creating a secret
```elixir
iex(1)> ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.create_secret("my-new-secret", "my-new-value")
:ok
```

### Deleting a secret
```elixir
iex(1)> ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.delete_secret("my-secret")
:ok
```

Based on [Ruby wrapper from stuartbarr](https://github.com/stuartbarr/azure-key-vault).
