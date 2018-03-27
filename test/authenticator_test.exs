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

  describe "ensure_authenticated/1 - signed in" do
    setup %{conn: conn} do
      [conn: Success.sign_in(conn, "foobar")]
    end

    test "passes thru", %{conn: conn} do
      conn = Success.sign_in(conn, "foobar")
      conn = Success.ensure_authenticated(conn)
      refute conn.private[:reason]
    end
  end

  describe "ensure_authenticated/1 - not signed in" do
    test "invokes the fallback with :unauthenticated", %{conn: conn} do
      conn = Success.ensure_authenticated(conn)
      assert conn.private.reason == :unauthenticated
    end
  end

  describe "authenticate_header/1 - header is set" do
    setup %{conn: conn} do
      [conn: Plug.Conn.put_req_header(conn, "authorization", "Bearer foobar")]
    end

    test "successful authentication", %{conn: conn} do
      conn = Success.authenticate_header(conn)
      assert conn.assigns.current_user == "foobar"
    end

    test "unsuccessful authentication", %{conn: conn} do
      conn = Failure.authenticate_header(conn)
      refute conn.assigns.current_user
      assert conn.private.reason == :fixture_failure
    end
  end

  describe "authenticate_header/1 - header is not set" do
    test "sets the user to nil", %{conn: conn} do
      conn = Success.authenticate_header(conn)
      assert conn.assigns.current_user == nil
      refute conn.private[:reason]
    end
  end

  describe "authenticate_session/1 - session is set" do
    setup %{conn: conn} do
      [conn: Plug.Conn.put_session(conn, :current_user, "foobar")]
    end

    test "successful authentication", %{conn: conn} do
      conn = Success.authenticate_session(conn)
      assert conn.assigns.current_user == "foobar"
    end

    test "unsuccessful authentication", %{conn: conn} do
      conn = Failure.authenticate_session(conn)
      refute conn.assigns.current_user
      assert conn.private.reason == :fixture_failure
    end
  end

  describe "authenticate_session/1 - header is not set" do
    test "sets the user to nil", %{conn: conn} do
      conn = Success.authenticate_session(conn)
      assert conn.assigns.current_user == nil
      refute conn.private[:reason]
    end
  end

  describe "ensure_unauthenticated/1 - signed in" do
    setup %{conn: conn} do
      [conn: Success.sign_in(conn, "foobar")]
    end

    test "invokes the fallback with :already_authenticated", %{conn: conn} do
      conn = Success.ensure_unauthenticated(conn)
      assert conn.private.reason == :already_authenticated
    end
  end

  describe "ensure_unauthenticated/1 - not signed in" do
    test "passes thru", %{conn: conn} do
      conn = Success.ensure_unauthenticated(conn)
      refute conn.private[:reason]
    end
  end
end
