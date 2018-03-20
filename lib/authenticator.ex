defmodule Authenticator do
  @type resource :: any()
  @type token :: String.t()
  @type reason :: atom()

  @callback tokenize(resource) :: {:ok, token} | {:error, reason}
  @callback authenticate(token) :: {:ok, resource} | {:error, reason}
  @callback fallback(conn :: Plug.Conn.t(), reason) :: Plug.Conn.t()

  defmacro __using__(config) do
    quote location: :keep do
      @behaviour Authenticator

      @scope Keyword.get(unquote(config), :scope, :current_user)

      @doc """
      Attempts to authenticate using the given token. If authentication is
      successful, the `conn.assigns.#{@scope}` will be assigned.

      If `authenticate/1` fails with `{:error, reason}`, the #{inspect(@scope)}
      will be signed out and `fallback/2` will be invoked.
      """
      @spec call(Plug.Conn.t(), Authenticator.token()) :: Plug.Conn.t()
      def call(conn, token) do
        case authenticate(token) do
          {:ok, resource} ->
            Plug.Conn.assign(conn, @scope, resource)

          {:error, reason} ->
            conn
            |> sign_out()
            |> fallback(reason)
        end
      end

      @doc """
      Stores the `#{inspect(@scope)}` in the session and sets `conn.assigns.#{@scope}`.

      If `tokenize/1` fails with `{:error, reason}`, the #{inspect(@scope)} will be
      signed out and `fallback/2` will be invoked.
      """
      @spec sign_in(Plug.Conn.t(), Authenticator.resource()) :: Plug.Conn.t()
      def sign_in(%Plug.Conn{} = conn, resource) do
        case tokenize(resource) do
          {:ok, token} ->
            conn
            |> Plug.Conn.assign(@scope, resource)
            |> case do
              %Plug.Conn{private: %{plug_session: _}} = conn ->
                Plug.Conn.put_session(conn, @scope, token)

              conn ->
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
        conn
        |> Plug.Conn.assign(@scope, nil)
        |> case do
          %Plug.Conn{private: %{plug_session: _}} = conn ->
            Plug.Conn.delete_session(conn, @scope)

          conn ->
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
      Verify that the conn is authenticated
      """
      @spec ensure_authenticated(Plug.Conn.t()) :: Plug.Conn.t()
      def ensure_authenticated(%Plug.Conn{} = conn) do
        if signed_in?(conn) do
          conn
        else
          fallback(conn, :not_authenticated)
        end
      end

      @doc "Verify that the conn is unauthenticated"
      @spec ensure_unauthenticated(Plug.Conn.t()) :: Plug.Conn.t()
      def ensure_unauthenticated(%Plug.Conn{} = conn) do
        if signed_in?(conn) do
          fallback(conn, :not_unauthenticated)
        else
          conn
        end
      end

      @doc "Get the authorization header from the request"
      @spec authenticate_header(Plug.Conn.t()) :: Plug.Conn.t()
      def authenticate_header(%Plug.Conn{} = conn) do
        case Plug.Conn.get_req_header(conn, "authorization") do
          ["Bearer " <> token] ->
            call(conn, token)

          _ ->
            Plug.Conn.assign(conn, @scope, conn.assigns[@scope])
        end
      end

      @doc "Fetch the token from the session"
      @spec authenticate_session(Plug.Conn.t()) :: Plug.Conn.t()
      def authenticate_session(%Plug.Conn{} = conn) do
        case Plug.Conn.get_session(conn, @scope) do
          nil ->
            Plug.Conn.assign(conn, @scope, conn.assigns[@scope])

          token ->
            call(conn, token)
        end
      end
    end
  end
end
