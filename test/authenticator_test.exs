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
    test "invokes the fallback", %{conn: conn} do
      conn = Failure.sign_in(conn, "foobar")
      assert conn.private.reason == :tokenize
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

  describe "signed_in?/1" do
    test "when the user is not set", %{conn: conn} do
      refute Success.signed_in?(conn)
    end

    test "when the user is set", %{conn: conn} do
      conn = Success.sign_in(conn, "foobar")
      assert Success.signed_in?(conn)
    end
  end

  describe "call/2" do
    test "user is authenticated", %{conn: conn} do
      conn = Success.call(conn, "foobar")
      assert conn.assigns.current_user == "foobar"
    end

    test "user is not authenticated", %{conn: conn} do
      conn = Failure.call(conn, "foobar")
      assert conn.assigns.current_user == nil
      assert conn.private.reason == :authenticate
    end
  end
end
