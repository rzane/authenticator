defmodule Authenticator.AuthenticatedTest do
  use Authenticator.ConnCase, async: true
  alias Authenticator.Fixtures.Success

  describe "when the user is signed in" do
    setup %{conn: conn} do
      [conn: Success.sign_in(conn, "foobar")]
    end

    test "passes thru", %{conn: conn} do
      conn = Success.Authenticated.call(conn, [])
      refute conn.private[:reason]
    end
  end

  describe "when the user is not signed in" do
    test "invokes the fallback with :not_authenticated", %{conn: conn} do
      conn = Success.Authenticated.call(conn, [])
      assert conn.private.reason == :not_authenticated
    end
  end
end
