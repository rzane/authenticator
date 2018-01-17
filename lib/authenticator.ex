defmodule Authenticator do
  @type resource :: any()
  @type token :: String.t()

  @callback tokenize(resource) :: {:ok, token} | :error
  @callback authenticate(token) :: {:ok, resource} | :error

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

          :error ->
            sign_out(conn)
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

      @doc """
      Extract a token from the session and authenticate the resource.
      """
      @spec authenticate_session(Plug.Conn.t()) :: Plug.Conn.t()
      def authenticate_session(conn) do
        do_authenticate(conn, Plug.Conn.get_session(conn, @scope))
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
            do_authenticate(conn, nil)
        end
      end

      defp do_authenticate(conn, nil) do
        Plug.Conn.assign(conn, @scope, nil)
      end

      defp do_authenticate(conn, token) do
        case authenticate(token) do
          {:ok, resource} ->
            Plug.Conn.assign(conn, @scope, resource)

          :error ->
            Plug.Conn.assign(conn, @scope, nil)
        end
      end
    end
  end
end
