defmodule Authenticator.UnauthenticatedTest do
  use Authenticator.ConnCase, async: true
  alias Authenticator.Fixtures.Success

  describe "when the user is signed in" do
    setup %{conn: conn} do
      [conn: Success.sign_in(conn, "foobar")]
    end

    test "invokes the fallback with :not_unauthenticated", %{conn: conn} do
      conn = Success.Unauthenticated.call(conn, [])
      assert conn.private.reason == :not_unauthenticated
    end
  end

  describe "when the user is not signed in" do
    test "passes thru", %{conn: conn} do
      conn = Success.Unauthenticated.call(conn, [])
      refute conn.private[:reason]
    end
  end
end
