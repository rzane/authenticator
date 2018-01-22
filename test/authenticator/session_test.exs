defmodule Authenticator.SessionTest do
  use Authenticator.ConnCase, async: true

  alias Authenticator.Session
  alias Authenticator.Fixtures.Success

  describe "when the session is set" do
    setup %{conn: conn} do
      [conn: Plug.Conn.put_session(conn, :current_user, "foobar")]
    end

    test "sets the user", %{conn: conn} do
      conn = Session.call(conn, Success)
      assert conn.assigns.current_user == "foobar"
    end
  end

  describe "when the header is not set" do
    test "sets the user to nil", %{conn: conn} do
      conn = Session.call(conn, Success)
      assert conn.assigns.current_user == nil
    end
  end
end
