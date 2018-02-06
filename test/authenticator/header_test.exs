defmodule Authenticator.HeaderTest do
  use Authenticator.ConnCase, async: true

  alias Authenticator.Header
  alias Authenticator.Fixtures.{Success, Failure}

  describe "when the header is set" do
    setup %{conn: conn} do
      [conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer foobar")]
    end

    test "successful authentication", %{conn: conn} do
      conn = Header.call(conn, with: Success)
      assert conn.assigns.current_user == "foobar"
    end

    test "unsuccessful authentication", %{conn: conn} do
      conn = Header.call(conn, with: Failure)
      refute conn.assigns.current_user
      assert conn.private.reason == :authenticate
    end
  end

  describe "when the header is not set" do
    test "sets the user to nil", %{conn: conn} do
      conn = Header.call(conn, with: Success)
      assert conn.assigns.current_user == nil
      refute conn.private[:reason]
    end
  end
end
