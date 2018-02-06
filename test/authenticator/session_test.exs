defmodule Authenticator.SessionTest do
  use Authenticator.ConnCase, async: true

  alias Authenticator.Session
  alias Authenticator.Fixtures.{Success, Failure}

  describe "when the session is set" do
    setup %{conn: conn} do
      [conn: Plug.Conn.put_session(conn, :current_user, "foobar")]
    end

    test "successful authentication", %{conn: conn} do
      conn = Session.call(conn, with: Success)
      assert conn.assigns.current_user == "foobar"
    end

    test "unsuccessful authentication", %{conn: conn} do
      conn = Session.call(conn, with: Failure)
      refute conn.assigns.current_user
      assert conn.private.reason == :authenticate
    end
  end

  describe "when the header is not set" do
    test "sets the user to nil", %{conn: conn} do
      conn = Session.call(conn, with: Success)
      assert conn.assigns.current_user == nil
      refute conn.private[:reason]
    end
  end
end
