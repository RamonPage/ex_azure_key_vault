defmodule ExAzureKeyVault.ClientTest do
  use ExUnit.Case, async: false
  doctest ExAzureKeyVault.Client, except: [
    connect: 0, connect: 4,
    get_secret: 2, get_secret: 3,
    create_secret: 3
  ]

  import Mock

  @client_id "690c027a-9b60-11e8-98d0-529269fb1459"
  @tenant_id "690c08ec-9b60-11e8-98d0-529269fb1459"
  @client_secret "690c0658-9b60-11e8-98d0-529269fb1459"
  @vault_name "my-vault"

  setup do
    %{
      client: ExAzureKeyVault.Client.new(
        "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        @vault_name,
        "2016-10-01"
      ),
      url: "https://login.windows.net/#{@tenant_id}/oauth2/token",
      body: {:form,
        [
          grant_type: "client_credentials",
          client_id: @client_id,
          client_secret: @client_secret,
          resource: "https://vault.azure.net"
        ]
      },
      headers: ["Content-Type": "application/x-www-form-urlencoded"],
      options: [ssl: [versions: [:"tlsv1.2"]]],
      expected_token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  end

  setup_all do
    on_exit fn ->
      ExAzureKeyVault.ClientTest.clean_application_config()
    end
  end

  describe "when application config is defined" do
    setup [:setup_application_config]

    test "connects to key vault without params", context do
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response_200_token(context) end] do
        result = ExAzureKeyVault.Client.connect()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == context[:client]
      end
    end
  end

  describe "when application config is not defined" do
    setup [:clean_application_config]

    test "connects to key vault with params", context do
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response_200_token(context) end] do
        result = ExAzureKeyVault.Client.connect(@vault_name, @tenant_id, @client_id, @client_secret)
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == context[:client]
      end
    end
  end

  describe "when environment variables are defined" do
    setup [:setup_environment_variables]

    test "connects to key vault with params", context do
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response_200_token(context) end] do
        result = ExAzureKeyVault.Client.connect()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == context[:client]
      end
    end
  end

  describe "when status code is 200" do
    setup [:setup_application_config]

    test "gets secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_200_value() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secret("my-secret")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:ok, "my-value"}
      end
    end

    test "creates secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        put: fn(_url, _body, _header, _options) -> response_200_value() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.create_secret("my-secret", "my-value")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == :ok
      end
    end
  end

  describe "when status code is 40x and body is empty" do
    setup [:setup_application_config]

    test "does not get secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_401_no_body() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secret("my-secret")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        {type, message} = result
        assert type == :error
        assert message =~ "Error: 401"
      end
    end

    test "does not create secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        put: fn(_url, _body, _header, _options) -> response_401_no_body() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.create_secret("my-secret", "my-value")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        {type, message} = result
        assert type == :error
        assert message =~ "Error: 401"
      end
    end
  end

  describe "when status code is 404 and body is not empty" do
    setup [:setup_application_config]

    test "does not get secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_404_error_message() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secret("my-secret")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, %{"error_message" => "Not found"}}
      end
    end

    test "does not create secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        put: fn(_url, _body, _header, _options) -> response_404_error_message() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.create_secret("my-secret", "my-value")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, %{"error_message" => "Not found"}}
      end
    end
  end

  describe "when status code is 40x and body is not empty" do
    setup [:setup_application_config]

    test "does not get secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_403_error_message() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secret("my-secret")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, %{"error_message" => "Forbidden"}}
      end
    end

    test "does not create secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        put: fn(_url, _body, _header, _options) -> response_403_error_message() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.create_secret("my-secret", "my-value")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, %{"error_message" => "Forbidden"}}
      end
    end
  end

  describe "when hostname is wrong" do
    setup [:setup_application_config]

    test "does not get secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_error_nxdomain() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secret("my-secret")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        {type, message} = result
        assert type == :error
        assert message =~ "Error: Couldn't resolve host name"
      end
    end

    test "does not create secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        put: fn(_url, _body, _header, _options) -> response_error_nxdomain() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.create_secret("my-secret", "my-value")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        {type, message} = result
        assert type == :error
        assert message =~ "Error: Couldn't resolve host name"
      end
    end
  end

  def clean_application_config() do
    clean_application_config("")
  end

  defp response_200_token(context) do
    {:ok, %HTTPoison.Response{
      body: "{\"access_token\":\"#{context[:expected_token]}\"}",
      status_code: 200
    }}
  end

  defp response_200_value() do
    {:ok, %HTTPoison.Response{
      body: "{\"value\":\"my-value\"}",
      status_code: 200
    }}
  end

  defp response_401_no_body() do
    {:ok, %HTTPoison.Response{
      body: "",
      status_code: 401
    }}
  end

  defp response_404_error_message() do
    {:ok, %HTTPoison.Response{
      body: "{\"error_message\":\"Not found\"}",
      status_code: 404
    }}
  end

  defp response_403_error_message() do
    {:ok, %HTTPoison.Response{
      body: "{\"error_message\":\"Forbidden\"}",
      status_code: 403
    }}
  end

  defp response_error_nxdomain() do
    {:error, %HTTPoison.Error{reason: :nxdomain}}
  end

  defp setup_environment_variables(_context) do
    System.put_env("AZURE_CLIENT_ID", @client_id)
    System.put_env("AZURE_CLIENT_SECRET", @client_secret)
    System.put_env("AZURE_TENANT_ID", @tenant_id)
    System.put_env("AZURE_VAULT_NAME", @vault_name)
    Application.put_env(:ex_azure_key_vault, :azure_client_id, {:system, "AZURE_CLIENT_ID"})
    Application.put_env(:ex_azure_key_vault, :azure_client_secret, {:system, "AZURE_CLIENT_SECRET"})
    Application.put_env(:ex_azure_key_vault, :azure_tenant_id, {:system, "AZURE_TENANT_ID"})
    Application.put_env(:ex_azure_key_vault, :azure_vault_name, {:system, "AZURE_VAULT_NAME"})
  end

  defp setup_application_config(_context) do
    Application.put_env(:ex_azure_key_vault, :azure_client_id, @client_id)
    Application.put_env(:ex_azure_key_vault, :azure_client_secret, @client_secret)
    Application.put_env(:ex_azure_key_vault, :azure_tenant_id, @tenant_id)
    Application.put_env(:ex_azure_key_vault, :azure_vault_name, @vault_name)
  end

  defp clean_application_config(_context) do
    Enum.each [
      :azure_client_id,
      :azure_client_secret,
      :azure_tenant_id,
      :azure_vault_name
    ], fn env ->
      Application.put_env(:ex_azure_key_vault, env, nil)
    end
    Enum.each [
      "AZURE_CLIENT_ID",
      "AZURE_CLIENT_SECRET",
      "AZURE_TENANT_ID",
      "AZURE_VAULT_NAME"
    ], fn env ->
      System.delete_env(env)
    end
  end
end
