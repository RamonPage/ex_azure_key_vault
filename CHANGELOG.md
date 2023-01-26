# Changelog

## v2.2.0

- Update Azure Key Vault API version to `7.3`.
- Updating dependencies:
  * `httpoison` to `~> 2.0.0`


## v2.1.1

- Minimum required Elixir version is now `~> 1.11`.
- Updating dependencies:
  * `jason` to `~> 1.4.0`
  * `joken` to `~> 2.5.0`


## v2.0.1

Updating dependencies.

* `httpoison` to `~> 1.8.0`
* `jason` to `~> 1.2.0`
* `joken` to `~> 2.3.0`

## v2.0.0

Removing `poison` dependency. Using `jason` instead.

## v1.0.2

Updating dependencies.

* `joken` to `~> 2.2.0`
* `jason` to `~> 1.2.0`
* `dialyxir` to `~> 1.0`
* `excoveralls` to `~> 0.12.0`

## v1.0.1

Updating dependencies.

* `httpoison` to `~> 1.6.0`

## v1.0.0

* Deprecating `certConnect()` in favor of `cert_connect()`, following Elixir naming convention.

## v0.3.0

* Adding support for client assertion to connect to Azure (using Azure App Registration certificate).

## v0.2.3

Updating dependencies.

* `ex_doc` to `~> 0.21.0`
* `excoveralls` to `0.11.1`

## v0.2.2

* Fixing `parse_trans` warnings.

## v0.2.1

* Fixing types.

## v0.2.0

* Adding support for delete secret.

## v0.1.0

* Adding support for get secrets.

## v0.0.2

* Fixing `ExAzureKeyVault.Client.connect()` with custom params when application env is predefined.

## v0.0.1

* Adding pre-release.