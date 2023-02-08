defmodule Mix.Tasks.Integration do
  use Mix.Task

  @impl Mix.Task
  def run(_) do
    current_date_time = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    connect_secret_name = "test-connect-name-#{current_date_time}"
    connect_secret_value = "test-connect-value-#{current_date_time}"

    cert_connect_secret_name = "test-cert-connect-name-#{current_date_time}"
    cert_connect_secret_value = "test-cert-connect-value-#{current_date_time}"

    Mix.Task.run("app.start")

    ###########################
    #                         #
    #      CLIENT SECRET      #
    #                         #
    ###########################

    Mix.shell().info("\n#### Using client secret ####\n")

    Mix.shell().info("Creating a secret...")
    status = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.create_secret(connect_secret_name, connect_secret_value)

    if :ok = status do
      Mix.shell().info("✅ #{status}\n")
    end

    Mix.shell().info("Getting a secret...")
    {status, result} = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secret(connect_secret_name)

    if :ok = status do
      Mix.shell().info("✅ #{result}\n")
    end

    Mix.shell().info("Getting secrets...")
    {status, result} = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets()

    if :ok = status do
      Mix.shell().info("✅ #{length(result["value"])} secrets found\n")
    end

    Mix.shell().info("Getting secrets on next link...")
    client = ExAzureKeyVault.Client.connect()
    {_, result} = client |> ExAzureKeyVault.Client.get_secrets(25)
    {next_status, next_result} = client |> ExAzureKeyVault.Client.get_secrets_next(result["nextLink"])

    if :ok = next_status do
      Mix.shell().info("✅ #{length(result["value"])} secrets found (page 1)")
      Mix.shell().info("✅ #{length(next_result["value"])} secrets found (page 2)\n")
    end

    Mix.shell().info("Deleting a secret...")
    status = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.delete_secret(connect_secret_name)

    if :ok = status do
      Mix.shell().info("✅ #{status}\n")
    end

    ##############################
    #                            #
    #      CLIENT ASSERTION      #
    #                            #
    ##############################

    Mix.shell().info("\n#### Using client assertion ####\n")

    Mix.shell().info("Creating a secret...")
    status = ExAzureKeyVault.Client.cert_connect() |> ExAzureKeyVault.Client.create_secret(cert_connect_secret_name, cert_connect_secret_value)

    if :ok = status do
      Mix.shell().info("✅ #{status}\n")
    end

    Mix.shell().info("Getting a secret...")
    {status, result} = ExAzureKeyVault.Client.cert_connect() |> ExAzureKeyVault.Client.get_secret(cert_connect_secret_name)

    if :ok = status do
      Mix.shell().info("✅ #{result}\n")
    end

    Mix.shell().info("Getting secrets...")
    {status, result} = ExAzureKeyVault.Client.cert_connect() |> ExAzureKeyVault.Client.get_secrets()

    if :ok = status do
      Mix.shell().info("✅ #{length(result["value"])} secrets found\n")
    end

    Mix.shell().info("Getting secrets on next link...")
    client = ExAzureKeyVault.Client.cert_connect()
    {_, result} = client |> ExAzureKeyVault.Client.get_secrets(25)
    {next_status, next_result} = client |> ExAzureKeyVault.Client.get_secrets_next(result["nextLink"])

    if :ok = next_status do
      Mix.shell().info("✅ #{length(result["value"])} secrets found (page 1)")
      Mix.shell().info("✅ #{length(next_result["value"])} secrets found (page 2)\n")
    end

    Mix.shell().info("Deleting a secret...")
    status = ExAzureKeyVault.Client.cert_connect() |> ExAzureKeyVault.Client.delete_secret(cert_connect_secret_name)

    if :ok = status do
      Mix.shell().info("✅ #{status}\n")
    end
  end
end
