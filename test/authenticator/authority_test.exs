defmodule Authenticator.AuthorityTest do
  use Authenticator.ConnCase, async: true

  alias Authenticator.Fixtures.Authority

  test "sign_in/2", %{conn: conn} do
    conn = Authority.sign_in(conn, "foobar")
    assert conn.assigns.current_user == "foobar"
  end

  test "call/2", %{conn: conn} do
    conn = Authority.call(conn, "foobar")
    assert conn.assigns.current_user == "foobar"
  end
end