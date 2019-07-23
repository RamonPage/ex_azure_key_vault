defmodule ExAzureKeyVault.ClientAssertionAuthTest do
  use ExUnit.Case, async: false
  doctest ExAzureKeyVault.ClientAssertionAuth, except: [ get_bearer_token: 1 ]

  import Mock

  setup do
    %{
      auth: ExAzureKeyVault.ClientAssertionAuth.new(
        "690c027a-9b60-11e8-98d0-529269fb1459",
        "690c0658-9b60-11e8-98d0-529269fb1459",
        "Dss7v2YI3GgCGflnLkxGN2kQ==",
        "-----BEGIN RSA PRIVATE KEY-----\nMIIBOwIBAAJBAM5fmXQmBacq1/f4XiMtvjSO49UwWu4fgGHBJyF7pAOA5r1PE3iz\nD8toaX7ioX7UconFVy76OFVPXNakLqgjIlsCAwEAAQJARRgw0nhgcCWiBT28lt6b\nzhEBKsFz0EHvw8rdhRJWSW1ms2/XeFqHOXf2beS4avmw5BOLzP9Pa5M0RWM/cZdG\n4QIhAPJEDoAVDI+wc9iSM/NRx25O7u9WPCd7az0iR+6O8FvjAiEA2hKlLrMgeTLK\nAXGmmmRgBJscCVYspFYpeZq+thEL2SkCIQDIsJwaelVnitLMq4ChpjNBK94/If6+\n7jyN7iIMexid5QIgUEdY484xgCyATPPHv0KATnHDanR8zqqhbhDXcDLqR7ECIQCj\n2YBHAMtrdWy8aSb5rey917SWbjf+V9BYwL/mUGriWQ==\n-----END RSA PRIVATE KEY-----"
      ),
      url: "https://login.microsoftonline.com/690c0658-9b60-11e8-98d0-529269fb1459/oauth2/v2.0/token",
      body: {:form,
        [
          grant_type: "client_credentials",
          client_id: "690c027a-9b60-11e8-98d0-529269fb1459",
          client_assertion: :_,
          client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
          scope: "https://vault.azure.net/.default"
        ]
      },
      headers: ["Content-Type": "application/x-www-form-urlencoded"],
      options: [ssl: [versions: [:"tlsv1.2"]]]
    }
  end

  describe "when status code is 200" do
    test "gets bearer token", context do
      expected_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      response = {:ok, %HTTPoison.Response{
        body: "{\"access_token\":\"#{expected_token}\"}",
        status_code: 200
      }}
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response end] do
        result = context[:auth] |> ExAzureKeyVault.ClientAssertionAuth.get_bearer_token()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:ok, "Bearer #{expected_token}"}
      end
    end
  end

  describe "when status code is 40x and body is empty" do
    test "shows custom error message", context do
      response = {:ok, %HTTPoison.Response{
        body: "",
        status_code: 401
      }}
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response end] do
        result = context[:auth] |> ExAzureKeyVault.ClientAssertionAuth.get_bearer_token()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, "Error: 401: #{context[:url]}"}
      end
    end
  end

  describe "when status code is 40x and body is not empty" do
    test "shows error message from body", context do
      response = {:ok, %HTTPoison.Response{
        body: "{\"error_message\":\"Not found\"}",
        status_code: 404
      }}
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response end] do
        result = context[:auth] |> ExAzureKeyVault.ClientAssertionAuth.get_bearer_token()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, %{"error_message" => "Not found"}}
      end
    end
  end

  describe "when hostname is wrong" do
    test "shows error message", context do
      error = {:error, %HTTPoison.Error{reason: :nxdomain}}
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> error end] do
        result = context[:auth] |> ExAzureKeyVault.ClientAssertionAuth.get_bearer_token()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        {type, message} = result
        assert type == :error
        assert message =~ "Error: Couldn't resolve host name"
      end
    end
  end

  describe "when an error occurs" do
    test "shows error message", context do
      error = {:error, %HTTPoison.Error{reason: :econnrefused}}
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> error end] do
        result = context[:auth] |> ExAzureKeyVault.ClientAssertionAuth.get_bearer_token()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, :econnrefused}
      end
    end
  end
end