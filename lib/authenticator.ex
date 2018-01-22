defmodule Authenticator do
  @type resource :: any()
  @type token :: String.t()
  @type reason :: atom()

  @callback tokenize(resource) :: {:ok, token} | {:error, reason}
  @callback authenticate(token) :: {:ok, resource} | {:error, reason}
  @callback fallback(Plug.Conn.t(), reason) :: Plug.Conn.t()

  defmacro __using__(config) do
    quote location: :keep do
      @behaviour Authenticator

      @scope Keyword.get(unquote(config), :scope, :current_user)

      @doc """
      Sign a resource in.
      """
      @spec sign_in(Plug.Conn.t(), Authenticator.resource()) :: Plug.Conn.t()
      def sign_in(%Plug.Conn{} = conn, resource) do
        case tokenize(resource) do
          {:ok, token} ->
            conn
            |> Plug.Conn.assign(@scope, resource)
            |> Plug.Conn.put_session(@scope, token)

          {:error, reason} ->
            conn
            |> sign_out()
            |> fallback(reason)
        end
      end

      @doc """
      Sign a resource out.
      """
      @spec sign_out(Plug.Conn.t()) :: Plug.Conn.t()
      def sign_out(%Plug.Conn{} = conn) do
        conn
        |> Plug.Conn.assign(@scope, nil)
        |> Plug.Conn.delete_session(@scope)
      end

      @spec signed_in?(Plug.Conn.t()) :: boolean()
      def signed_in?(%Plug.Conn{} = conn) do
        not is_nil(conn.assigns[@scope])
      end

      @doc """
      Extract a token from the session and authenticate the resource.
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
      Extract a token from the Authorization header and authenticate the user.
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
