defmodule Authenticator do
  @type resource :: any()
  @type token :: String.t()

  @callback tokenize(resource) :: {:ok, token} | {:error, reason :: atom()}
  @callback authenticate(token) :: {:ok, resource} | {:error, reason :: atom()}
  @callback fallback(conn :: Plug.Conn.t(), reason :: atom()) :: Plug.Conn.t()

  defmacro __using__(config) do
    quote location: :keep do
      @behaviour Authenticator

      @scope Keyword.get(unquote(config), :scope, :current_user)

      @doc """
      Stores the `#{inspect(@scope)}` in the session and sets `conn.assigns.#{@scope}`.

      If `tokenize/1` fails with `{:error, reason}`, the #{inspect(@scope)} will be
      signed out and `fallback/2` will be invoked.
      """
      @spec sign_in(Plug.Conn.t(), Authenticator.resource()) :: Plug.Conn.t()
      def sign_in(%Plug.Conn{} = conn, resource) do
        case tokenize(resource) do
          {:ok, token} ->
            conn = Plug.Conn.assign(conn, @scope, resource)

            if session_configured?(conn) do
              Plug.Conn.put_session(conn, @scope, token)
            else
              conn
            end

          {:error, reason} ->
            conn
            |> sign_out()
            |> fallback(reason)
        end
      end

      @doc """
      Deletes the `#{inspect(@scope)}` from the session and sets`conn.assigns.#{@scope}`
      to `nil`.
      """
      @spec sign_out(Plug.Conn.t()) :: Plug.Conn.t()
      def sign_out(%Plug.Conn{} = conn) do
        conn = Plug.Conn.assign(conn, @scope, nil)

        if session_configured?(conn) do
          Plug.Conn.delete_session(conn, @scope)
        else
          conn
        end
      end

      @doc """
      Check to see if there is a #{inspect(@scope)} signed in.
      """
      @spec signed_in?(Plug.Conn.t()) :: boolean()
      def signed_in?(%Plug.Conn{} = conn) do
        not is_nil(conn.assigns[@scope])
      end

      @doc """
      Extract a "token" from the session and authenticates the resource.
      """
      @spec authenticate_session(Plug.Conn.t()) :: Plug.Conn.t()
      def authenticate_session(conn) do
        case Plug.Conn.get_session(conn, @scope) do
          nil ->
            ensure_assigned(conn)

          token ->
            do_authenticate(conn, token)
        end
      end

      @doc """
      Extract a token from the `Authorization` header and authenticate the user. The
      `Authorization` header is expected to be in the following format: `Bearer <the token>`.
      """
      @spec authenticate_header(Plug.Conn.t()) :: Plug.Conn.t()
      def authenticate_header(conn) do
        case Plug.Conn.get_req_header(conn, "authorization") do
          ["Bearer " <> token] ->
            do_authenticate(conn, token)

          _ ->
            ensure_assigned(conn)
        end
      end

      # Does the `conn` have a session? In the case of an API, there
      # won't be a session available.
      defp session_configured?(conn) do
        Map.has_key?(conn.private, :plug_session)
      end

      # Make sure `@current_user` is set.
      defp ensure_assigned(conn) do
        Plug.Conn.assign(conn, @scope, conn.assigns[@scope])
      end

      defp do_authenticate(conn, token) do
        case authenticate(token) do
          {:ok, resource} ->
            Plug.Conn.assign(conn, @scope, resource)

          {:error, reason} ->
            conn
            |> sign_out()
            |> fallback(reason)
        end
      end
    end
  end
end
