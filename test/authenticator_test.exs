defmodule AuthenticatorTest do
  use Authenticator.ConnCase, async: true

  alias Authenticator.Fixtures.{Success, Failure}

  describe "sign_in/2 when tokenize/1 is successful" do
    test "assigns the scope", %{conn: conn} do
      conn = Success.sign_in(conn, "foobar")
      assert conn.assigns.current_user == "foobar"
    end

    test "stores the token", %{conn: conn} do
      conn = Success.sign_in(conn, "foobar")
      assert get_session(conn, :current_user) == "foobar"
    end
  end

  describe "sign_in/2 when tokenize/1 fails" do
    setup %{conn: conn} do
      [conn: Success.sign_in(conn, "foobar")]
    end

    test "clears the scope", %{conn: conn} do
      conn = Failure.sign_in(conn, "foobar")
      assert conn.assigns.current_user == nil
    end

    test "clears the session", %{conn: conn} do
      conn = Failure.sign_in(conn, "foobar")
      assert get_session(conn, :current_user) == nil
    end
  end

  describe "sign_out/1" do
    setup %{conn: conn} do
      [conn: Success.sign_in(conn, "foobar")]
    end

    test "clears the scope", %{conn: conn} do
      conn = Success.sign_out(conn)
      assert conn.assigns.current_user == nil
    end

    test "clears the session", %{conn: conn} do
      conn = Success.sign_out(conn)
      assert get_session(conn, :current_user) == nil
    end
  end

  describe "authenticate_session/1" do
    test "user is authenticated", %{conn: conn} do
      conn =
        conn
        |> put_session(:current_user, "foobar")
        |> Success.authenticate_session()

      assert conn.assigns.current_user == "foobar"
    end

    test "user is not authenticated", %{conn: conn} do
      conn =
        conn
        |> put_session(:current_user, "foobar")
        |> Failure.authenticate_session()

      assert conn.assigns.current_user == nil
    end

    test "no session", %{conn: conn} do
      conn = Success.authenticate_session(conn)
      assert conn.assigns.current_user == nil
    end
  end

  describe "authenticate_token/1" do
    test "user is authenticated", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer foobar")
        |> Success.authenticate_header()

      assert conn.assigns.current_user == "foobar"
    end

    test "user is not authenticated", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer foobar")
        |> Failure.authenticate_header()

      assert conn.assigns.current_user == nil
    end

    test "no header", %{conn: conn} do
      conn = Success.authenticate_header(conn)
      assert conn.assigns.current_user == nil
    end
  end
end
