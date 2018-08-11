defmodule ExAzureKeyVault.AuthTest do
  use ExUnit.Case, async: false
  doctest ExAzureKeyVault.Auth, except: [ get_bearer_token: 1 ]

  import Mock

  setup do
    %{
      auth: ExAzureKeyVault.Auth.new(
        "690c027a-9b60-11e8-98d0-529269fb1459",
        "690c0658-9b60-11e8-98d0-529269fb1459",
        "690c08ec-9b60-11e8-98d0-529269fb1459"
      ),
      url: "https://login.windows.net/690c08ec-9b60-11e8-98d0-529269fb1459/oauth2/token",
      body: {:form,
        [
          grant_type: "client_credentials",
          client_id: "690c027a-9b60-11e8-98d0-529269fb1459",
          client_secret: "690c0658-9b60-11e8-98d0-529269fb1459",
          resource: "https://vault.azure.net"
        ]
      },
      headers: ["Content-Type": "application/x-www-form-urlencoded"],
      options: [ssl: [versions: [:"tlsv1.2"]]]
    }
  end

  describe "when status code is 200" do
    test "gets bearer token", context do
      expected_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      response = { :ok, %HTTPoison.Response{
        body: "{\"access_token\":\"#{expected_token}\"}",
        status_code: 200
      }}
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response end] do
        result = context[:auth] |> ExAzureKeyVault.Auth.get_bearer_token()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:ok, "Bearer #{expected_token}"}
      end
    end
  end

  describe "when status code is 40x and body is empty" do
    test "shows custom error message", context do
      response = { :ok, %HTTPoison.Response{
        body: "",
        status_code: 401
      }}
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response end] do
        result = context[:auth] |> ExAzureKeyVault.Auth.get_bearer_token()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, "Error: 401: #{context[:url]}"}
      end
    end
  end

  describe "when status code is 40x and body is not empty" do
    test "shows error message from body", context do
      response = { :ok, %HTTPoison.Response{
        body: "{\"error_message\":\"Not found\"}",
        status_code: 404
      }}
      with_mock HTTPoison, [post: fn(_url, _body, _header, _options) -> response end] do
        result = context[:auth] |> ExAzureKeyVault.Auth.get_bearer_token()
        assert_called HTTPoison.post(context[:url], context[:body], context[:headers], context[:options])
        assert result == {:error, %{"error_message" => "Not found"}}
      end
    end
  end
end