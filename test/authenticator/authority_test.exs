defmodule Authenticator.AuthorityTest do
  use Authenticator.ConnCase, async: true

  alias Authenticator.Fixtures.Authority

  test "sign_in/2", %{conn: conn} do
    conn = Authority.sign_in(conn, "foobar")
    assert conn.assigns.current_user == "foobar"
  end

  test "authenticate_header/2", %{conn: conn} do
    conn = Plug.Conn.put_req_header(conn, "authorization", "Bearer foobar")
    conn = Authority.authenticate_header(conn)
    assert conn.assigns.current_user == "foobar"
  end
end
