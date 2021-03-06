defmodule Authenticator do
  @moduledoc """
  Generates a module for authenticating requests based on the `Plug.Conn`.

  ### Example

      defmodule MyAppWeb.Authentication do
        use Authenticator, fallback: MyAppWeb.FallbackController

        alias MyApp.Repo
        alias MyApp.Accounts.User

        @impl true
        def tokenize(user) do
          {:ok, to_string(user.id)}
        end

        @impl true
        def authenticate(user_id) do
          case Repo.get(User, user_id) do
            nil ->
              {:error, :unauthenticated}

            user ->
              {:ok, user}
          end
        end
      end

  """

  @type resource :: any()
  @type token :: String.t()
  @type reason :: atom()

  @callback tokenize(resource) :: {:ok, token} | {:error, reason}
  @callback authenticate(token) :: {:ok, resource} | {:error, reason}

  defmacro __using__(config) do
    quote location: :keep do
      @behaviour Authenticator

      @scope Keyword.get(unquote(config), :scope, :current_user)
      @fallback Keyword.fetch!(unquote(config), :fallback)

      @doc """
      Stores the `#{@scope}` in the session and sets `conn.assigns.#{@scope}`.

      If `tokenize/1` fails with `{:error, reason}`, the #{@scope} will be
      signed out and the `:fallback` will be invoked.

      ## Options

        * `:session` - When `false`, the session will not be modified. This is useful
          for APIs that don't use sessions.

      """
      @spec sign_in(Plug.Conn.t(), Authenticator.resource()) :: Plug.Conn.t()
      def sign_in(%Plug.Conn{} = conn, resource, opts \\ []) do
        case tokenize(resource) do
          {:ok, token} ->
            conn = Plug.Conn.assign(conn, @scope, resource)

            if Keyword.get(opts, :session, true) do
              Plug.Conn.put_session(conn, @scope, token)
            else
              conn
            end

          {:error, reason} ->
            conn
            |> sign_out(opts)
            |> @fallback.call({:error, reason})
        end
      end

      @doc """
      Deletes the `#{@scope}` from the session and sets `conn.assigns.#{@scope}`
      to `nil`.

      ## Options

        * `:session` - When `false`, the session will not be modified. This is useful
          for APIs that don't use sessions.

      """
      @spec sign_out(Plug.Conn.t()) :: Plug.Conn.t()
      def sign_out(%Plug.Conn{} = conn, opts \\ []) do
        opts = Keyword.put_new(opts, :session, true)
        conn = Plug.Conn.assign(conn, @scope, nil)

        if Keyword.get(opts, :session, true) do
          Plug.Conn.delete_session(conn, @scope)
        else
          conn
        end
      end

      @doc """
      Check to see if there is a `#{@scope}` signed in.
      """
      @spec signed_in?(Plug.Conn.t()) :: boolean()
      def signed_in?(%Plug.Conn{} = conn) do
        not is_nil(conn.assigns[@scope])
      end

      @doc """
      Requires the user to be authenticated. If the user is not
      authenticated, the `:fallback` will be called with a reason
      of `{:error, :unauthenticated}`.
      """
      @spec ensure_authenticated(Plug.Conn.t()) :: Plug.Conn.t()
      def ensure_authenticated(%Plug.Conn{} = conn, _opts \\ []) do
        if signed_in?(conn) do
          conn
        else
          @fallback.call(conn, {:error, :unauthenticated})
        end
      end

      @doc """
      Requires the user to *not* be unauthenticated. If the
      user is authenticated, the `:fallback` function will
      be called with a reason of `{:error, :already_authenticated}`.
      """
      @spec ensure_unauthenticated(Plug.Conn.t()) :: Plug.Conn.t()
      def ensure_unauthenticated(%Plug.Conn{} = conn, _opts \\ []) do
        if signed_in?(conn) do
          @fallback.call(conn, {:error, :already_authenticated})
        else
          conn
        end
      end

      @doc """
      Authenticates a resource from the `Authorization` header. The
      header is expected to conform to the following format:

          Bearer <token>

      If the header is not present or has an invalid format, this plug won't do anything.

      ## Examples

          pipeline :api do
            # ... snip
            plug :authenticate_header
          end

          pipeline :authenticated do
            plug :ensure_authenticated
          end

          scope "/api" do
            pipe_through [:api, :authenticated]

            # protected routes here
          end

      """
      @spec authenticate_header(Plug.Conn.t()) :: Plug.Conn.t()
      def authenticate_header(%Plug.Conn{} = conn, _opts \\ []) do
        case Plug.Conn.get_req_header(conn, "authorization") do
          ["Bearer " <> token] ->
            do_authenticate(conn, token, session: false)

          _ ->
            Plug.Conn.assign(conn, @scope, conn.assigns[@scope])
        end
      end

      @doc """
      Authenticates a resource from the session.

      If the header is not present or has an invalid format, this plug won't do anything.

      ## Examples

          pipeline :browser do
            # ... snip
            plug :authenticate_session
          end

          pipeline :authenticated do
            plug :ensure_authenticated
          end

          scope "/" do
            pipe_through [:browser, :authenticated]

            # protected routes here
          end

      """
      @spec authenticate_session(Plug.Conn.t()) :: Plug.Conn.t()
      def authenticate_session(%Plug.Conn{} = conn, _opts \\ []) do
        case Plug.Conn.get_session(conn, @scope) do
          nil ->
            Plug.Conn.assign(conn, @scope, conn.assigns[@scope])

          token ->
            do_authenticate(conn, token)
        end
      end

      defp do_authenticate(conn, token, opts \\ []) do
        case authenticate(token) do
          {:ok, resource} ->
            Plug.Conn.assign(conn, @scope, resource)

          {:error, reason} ->
            conn
            |> sign_out(opts)
            |> @fallback.call({:error, reason})
        end
      end
    end
  end
end
