defmodule Authenticator.HeaderTest do
  use Authenticator.ConnCase, async: true

  alias Authenticator.Header
  alias Authenticator.Fixtures.Success

  describe "when the header is set" do
    setup %{conn: conn} do
      [conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer foobar")]
    end

    test "sets the user", %{conn: conn} do
      conn = Header.call(conn, Success)
      assert conn.assigns.current_user == "foobar"
    end
  end

  describe "when the header is not set" do
    test "sets the user to nil", %{conn: conn} do
      conn = Header.call(conn, Success)
      assert conn.assigns.current_user == nil
    end
  end
end
