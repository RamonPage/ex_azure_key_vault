defmodule ExAzureKeyVault.ClientTest do
  use ExUnit.Case, async: false
  doctest ExAzureKeyVault.Client, except: [
    connect: 0, connect: 4,
    cert_connect: 0, cert_connect: 5,
    get_secret: 2, get_secret: 3,
    get_secrets: 1, get_secrets: 2,
    get_secrets_next: 2,
    create_secret: 3, delete_secret: 2
  ]

  import Mock

  @client_id "690c027a-9b60-11e8-98d0-529269fb1459"
  @tenant_id "690c08ec-9b60-11e8-98d0-529269fb1459"
  @client_secret "690c0658-9b60-11e8-98d0-529269fb1459"
  @vault_name "my-vault"
  @cert_base64_thumbprint "Dss7v2YI3GgCGflnLkxGN2kQ=="
  @cert_private_key_pem "-----BEGIN RSA PRIVATE KEY-----\nMIIBOwIBAAJBAM5fmXQmBacq1/f4XiMtvjSO49UwWu4fgGHBJyF7pAOA5r1PE3iz\nD8toaX7ioX7UconFVy76OFVPXNakLqgjIlsCAwEAAQJARRgw0nhgcCWiBT28lt6b\nzhEBKsFz0EHvw8rdhRJWSW1ms2/XeFqHOXf2beS4avmw5BOLzP9Pa5M0RWM/cZdG\n4QIhAPJEDoAVDI+wc9iSM/NRx25O7u9WPCd7az0iR+6O8FvjAiEA2hKlLrMgeTLK\nAXGmmmRgBJscCVYspFYpeZq+thEL2SkCIQDIsJwaelVnitLMq4ChpjNBK94/If6+\n7jyN7iIMexid5QIgUEdY484xgCyATPPHv0KATnHDanR8zqqhbhDXcDLqR7ECIQCj\n2YBHAMtrdWy8aSb5rey917SWbjf+V9BYwL/mUGriWQ==\n-----END RSA PRIVATE KEY-----"

  setup do
    %{
      client: ExAzureKeyVault.Client.new(
        "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        @vault_name,
        "2016-10-01"
      ),
      client_with_custom_params: ExAzureKeyVault.Client.new(
        "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "another-vault",
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
      certUrl: "https://login.microsoftonline.com/#{@tenant_id}/oauth2/v2.0/token",
      certBody: {:form,
        [
          grant_type: "client_credentials",
          client_id: @client_id,
          client_assertion: :_,
          client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
          scope: "https://vault.azure.net/.default"
        ]
      },
      headers: ["Content-Type": "application/x-www-form-urlencoded"],
      options: [ssl: [versions: [:"tlsv1.2"]]],
      expected_token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      next_link: "https://#{@vault_name}.vault.azure.net:443/secrets?api-version=2016-10-01&$skiptoken=eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6...&maxresults=2",
      secrets_list: %{
        "nextLink" => nil,
        "value" => [
          %{
            "attributes" => %{
              "created" => 1533704004,
              "enabled" => true,
              "recoveryLevel" => "Purgeable",
              "updated" => 1533704004
            },
            "id" => "https://#{@vault_name}.vault.azure.net/secrets/my-secret"
          },
          %{
            "attributes" => %{
              "created" => 1532633078,
              "enabled" => true,
              "recoveryLevel" => "Purgeable",
              "updated" => 1532633078
            },
            "id" => "https://#{@vault_name}.vault.azure.net/secrets/another-secret"
          },
          %{
            "attributes" => %{
              "created" => 1532633078,
              "enabled" => true,
              "recoveryLevel" => "Purgeable",
              "updated" => 1532633078
            },
            "id" => "https://#{@vault_name}.vault.azure.net/secrets/test-secret"
          }
        ]
      }
    }
  end

  setup_all do
    on_exit fn ->
      ExAzureKeyVault.ClientTest.clean_application_config()
    end
  end

  describe "connect() when application config is defined" do
    setup [:setup_application_config]

    test "connects to key vault without params", context do
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response_200_token(context) end] do
        result = ExAzureKeyVault.Client.connect()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == context[:client]
      end
    end

    test "connects to key vault with custom params", context do
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response_200_token(context) end] do
        result = ExAzureKeyVault.Client.connect("another-vault")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == context[:client_with_custom_params]
      end
    end
  end

  describe "cert_connect() when application config is defined" do
    setup [:setup_application_config]

    test "connects to key vault without params", context do
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response_200_token(context) end] do
        result = ExAzureKeyVault.Client.cert_connect()
        assert_called HTTPoison.post(context[:certUrl], context[:certBody], context[:headers], context[:options])
        assert result == context[:client]
      end
    end

    test "connects to key vault with custom params", context do
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response_200_token(context) end] do
        result = ExAzureKeyVault.Client.cert_connect("another-vault")
        assert_called HTTPoison.post(context[:certUrl], context[:certBody], context[:headers], context[:options])
        assert result == context[:client_with_custom_params]
      end
    end
  end

  describe "connect() when application config is not defined" do
    setup [:clean_application_config]

    test "connects to key vault with params", context do
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response_200_token(context) end] do
        result = ExAzureKeyVault.Client.connect(@vault_name, @tenant_id, @client_id, @client_secret)
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == context[:client]
      end
    end

    test "raises ArgumentError when vault name is not present" do
      assert_raise ArgumentError, "Vault name is not present", fn ->
        ExAzureKeyVault.Client.connect(nil, @tenant_id, @client_id, @client_secret)
      end
    end

    test "raises ArgumentError when tenant id is not present" do
      assert_raise ArgumentError, "Tenant ID is not present", fn ->
        ExAzureKeyVault.Client.connect(@vault_name, nil, @client_id, @client_secret)
      end
    end

    test "raises ArgumentError when client id is not present" do
      assert_raise ArgumentError, "Client ID is not present", fn ->
        ExAzureKeyVault.Client.connect(@vault_name, @tenant_id, nil, @client_secret)
      end
    end

    test "raises ArgumentError when client secret is not present" do
      assert_raise ArgumentError, "Client secret is not present", fn ->
        ExAzureKeyVault.Client.connect(@vault_name, @tenant_id, @client_id, nil)
      end
    end
  end

  describe "cert_connect() when application config is not defined" do
    setup [:clean_application_config]

    test "connects to key vault with params", context do
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response_200_token(context) end] do
        result = ExAzureKeyVault.Client.cert_connect(@vault_name, @tenant_id, @client_id, @cert_base64_thumbprint, @cert_private_key_pem)
        assert_called HTTPoison.post(context[:certUrl], context[:certBody], context[:headers], context[:options])
        assert result == context[:client]
      end
    end

    test "raises ArgumentError when vault name is not present" do
      assert_raise ArgumentError, "Vault name is not present", fn ->
        ExAzureKeyVault.Client.cert_connect(nil, @tenant_id, @client_id, @cert_base64_thumbprint, @cert_private_key_pem)
      end
    end

    test "raises ArgumentError when tenant id is not present" do
      assert_raise ArgumentError, "Tenant ID is not present", fn ->
        ExAzureKeyVault.Client.cert_connect(@vault_name, nil, @client_id, @cert_base64_thumbprint, @cert_private_key_pem)
      end
    end

    test "raises ArgumentError when client id is not present" do
      assert_raise ArgumentError, "Client ID is not present", fn ->
        ExAzureKeyVault.Client.cert_connect(@vault_name, @tenant_id, nil, @cert_base64_thumbprint, @cert_private_key_pem)
      end
    end

    test "raises ArgumentError when certificate base64 thumbprint is not present" do
      assert_raise ArgumentError, "Certificate base64 thumbprint is not present", fn ->
        ExAzureKeyVault.Client.cert_connect(@vault_name, @tenant_id, @client_id, nil, @cert_private_key_pem)
      end
    end

    test "raises ArgumentError when certificate private PEM is not present" do
      assert_raise ArgumentError, "Certificate private key PEM is not present", fn ->
        ExAzureKeyVault.Client.cert_connect(@vault_name, @tenant_id, @client_id, @cert_base64_thumbprint, nil)
      end
    end
  end

  describe "when environment variables are defined" do
    setup [:setup_environment_variables]

    test "connects to key vault without params", context do
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

    test "lists secrets", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_200_list() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:ok, context[:secrets_list]}
      end
    end

    test "lists next secrets", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_200_list() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets_next(context[:next_link])
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:ok, context[:secrets_list]}
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

    test "deletes secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        delete: fn(_url, _header, _options) -> response_200_value() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.delete_secret("my-secret")
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

    test "does not list secrets", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_401_no_body() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        {type, message} = result
        assert type == :error
        assert message =~ "Error: 401"
      end
    end

    test "does not list next secrets", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_401_no_body() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets_next(context[:next_link])
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

    test "does not delete secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        delete: fn(_url, _header, _options) -> response_401_no_body() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.delete_secret("my-secret")
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

    test "does not delete secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        delete: fn(_url, _header, _options) -> response_404_error_message() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.delete_secret("my-secret")
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

    test "does not list secrets", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_403_error_message() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, %{"error_message" => "Forbidden"}}
      end
    end

    test "does not list next secrets", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_403_error_message() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets_next(context[:next_link])
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

    test "does not delete secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        delete: fn(_url, _header, _options) -> response_403_error_message() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.delete_secret("my-secret")
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

    test "does not list secrets", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_error_nxdomain() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        {type, message} = result
        assert type == :error
        assert message =~ "Error: Couldn't resolve host name"
      end
    end

    test "does not list next secrets", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_error_nxdomain() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets_next(context[:next_link])
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

    test "does not delete secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        delete: fn(_url, _header, _options) -> response_error_nxdomain() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.delete_secret("my-secret")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        {type, message} = result
        assert type == :error
        assert message =~ "Error: Couldn't resolve host name"
      end
    end
  end

  describe "when an error occurs" do
    setup [:setup_application_config]

    test "does not get secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_error_econnrefused() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secret("my-secret")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, :econnrefused}
      end
    end

    test "does not list secrets", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_error_econnrefused() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, :econnrefused}
      end
    end

    test "does not list next secrets", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        get: fn(_url, _header, _options) -> response_error_econnrefused() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets_next(context[:next_link])
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, :econnrefused}
      end
    end

    test "does not create secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        put: fn(_url, _body, _header, _options) -> response_error_econnrefused() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.create_secret("my-secret", "my-value")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, :econnrefused}
      end
    end

    test "does not delete secret", context do
      with_mock HTTPoison, [
        post: fn(_url, _body, _header, _options) -> response_200_token(context) end,
        delete: fn(_url, _header, _options) -> response_error_econnrefused() end
      ] do
        result = ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.delete_secret("my-secret")
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, :econnrefused}
      end
    end
  end

  describe "when next link is invalid" do
    setup [:setup_application_config]

    test "does not list next secrets", context do
      assert_raise ArgumentError, "Next link https://azure.microsoft.com is not valid", fn ->
        with_mock HTTPoison, [
          post: fn(_url, _body, _header, _options) -> response_200_token(context) end
        ] do
          ExAzureKeyVault.Client.connect() |> ExAzureKeyVault.Client.get_secrets_next("https://azure.microsoft.com")
          assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        end
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

  defp response_200_list() do
    {:ok, %HTTPoison.Response{
      body: "{\"value\":
        [{
          \"id\":\"https://#{@vault_name}.vault.azure.net/secrets/my-secret\",
          \"attributes\":{
            \"updated\":1533704004,
            \"recoveryLevel\":\"Purgeable\",
            \"enabled\":true,
            \"created\":1533704004
          }
        },{
          \"id\":\"https://#{@vault_name}.vault.azure.net/secrets/another-secret\",
          \"attributes\":{
            \"updated\":1532633078,
            \"recoveryLevel\":\"Purgeable\",
            \"enabled\":true,
            \"created\":1532633078
          }
        },{
          \"id\":\"https://#{@vault_name}.vault.azure.net/secrets/test-secret\",
          \"attributes\":{
            \"updated\":1532633078,
            \"recoveryLevel\":\"Purgeable\",
            \"enabled\":true,
            \"created\":1532633078
          }
        }],\"nextLink\":null}",
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

  defp response_error_econnrefused() do
    {:error, %HTTPoison.Error{reason: :econnrefused}}
  end

  defp setup_environment_variables(_context) do
    System.put_env("AZURE_CLIENT_ID", @client_id)
    System.put_env("AZURE_CLIENT_SECRET", @client_secret)
    System.put_env("AZURE_TENANT_ID", @tenant_id)
    System.put_env("AZURE_VAULT_NAME", @vault_name)
    System.put_env("AZURE_CERT_BASE64_THUMBPRINT", @cert_base64_thumbprint)
    System.put_env("AZURE_CERT_PRIVATE_KEY_PEM", @cert_private_key_pem)
    Application.put_env(:ex_azure_key_vault, :azure_client_id, {:system, "AZURE_CLIENT_ID"})
    Application.put_env(:ex_azure_key_vault, :azure_client_secret, {:system, "AZURE_CLIENT_SECRET"})
    Application.put_env(:ex_azure_key_vault, :azure_tenant_id, {:system, "AZURE_TENANT_ID"})
    Application.put_env(:ex_azure_key_vault, :azure_vault_name, {:system, "AZURE_VAULT_NAME"})
    Application.put_env(:ex_azure_key_vault, :azure_cert_base64_thumbprint, {:system, "AZURE_CERT_BASE64_THUMBPRINT"})
    Application.put_env(:ex_azure_key_vault, :azure_cert_private_key_pem, {:system, "AZURE_CERT_PRIVATE_KEY_PEM"})
  end

  defp setup_application_config(_context) do
    Application.put_env(:ex_azure_key_vault, :azure_client_id, @client_id)
    Application.put_env(:ex_azure_key_vault, :azure_client_secret, @client_secret)
    Application.put_env(:ex_azure_key_vault, :azure_tenant_id, @tenant_id)
    Application.put_env(:ex_azure_key_vault, :azure_vault_name, @vault_name)
    Application.put_env(:ex_azure_key_vault, :azure_cert_base64_thumbprint, @cert_base64_thumbprint)
    Application.put_env(:ex_azure_key_vault, :azure_cert_private_key_pem, @cert_private_key_pem)
  end

  defp clean_application_config(_context) do
    Enum.each [
      :azure_client_id,
      :azure_client_secret,
      :azure_tenant_id,
      :azure_vault_name,
      :azure_cert_base64_thumbprint,
      :azure_cert_private_key_pem
    ], fn env ->
      Application.put_env(:ex_azure_key_vault, env, nil)
    end
    Enum.each [
      "AZURE_CLIENT_ID",
      "AZURE_CLIENT_SECRET",
      "AZURE_TENANT_ID",
      "AZURE_VAULT_NAME",
      "AZURE_CERT_BASE64_THUMBPRINT",
      "AZURE_CERT_PRIVATE_KEY_PEM"
    ], fn env ->
      System.delete_env(env)
    end
  end
end
