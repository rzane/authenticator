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
            assign(conn, resource)

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
            |> assign(resource)
            |> put_session(token)

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
        |> assign(nil)
        |> delete_session()
      end

      @doc """
      Check to see if there is a #{inspect(@scope)} signed in.
      """
      @spec signed_in?(Plug.Conn.t()) :: boolean()
      def signed_in?(%Plug.Conn{} = conn) do
        not is_nil(conn.assigns[@scope])
      end

      @doc """
      Gets the token from the session.
      """
      @spec get_session(Plug.Conn.t()) :: any()
      def get_session(conn) do
        if session_configured?(conn) do
          Plug.Conn.get_session(conn, @scope)
        end
      end

      @doc """
      Deletes the token from the session.
      """
      @spec delete_session(Plug.Conn.t()) :: Plug.Conn.t()
      def delete_session(conn) do
        if session_configured?(conn) do
          Plug.Conn.delete_session(conn, @scope)
        else
          conn
        end
      end

      @doc """
      Sets the token in the session.
      """
      @spec put_session(Plug.Conn.t(), any()) :: Plug.Conn.t()
      def put_session(conn, token) do
        if session_configured?(conn) do
          Plug.Conn.put_session(conn, @scope, token)
        else
          conn
        end
      end

      @doc """
      Make sure `conn.assigns.#{@scope}` has been set.
      """
      @spec assign(Plug.Conn.t()) :: Plug.Conn.t()
      def assign(conn) do
        assign(conn, conn.assigns[@scope])
      end

      @doc """
      Set the vaue of `conn.assigns.#{@scope}`.
      """
      @spec assign(Plug.Conn.t(), Authenticator.resource()) :: Plug.Conn.t()
      def assign(conn, resource) do
        Plug.Conn.assign(conn, @scope, resource)
      end

      defp session_configured?(conn) do
        Map.has_key?(conn.private, :plug_session)
      end

      Authenticator.defplug(__MODULE__, :Header)
      Authenticator.defplug(__MODULE__, :Session)
      Authenticator.defplug(__MODULE__, :Authenticated)
      Authenticator.defplug(__MODULE__, :Unauthenticated)
    end
  end

  @doc false
  defmacro defplug(authenticator, name) do
    plug = Module.concat(Authenticator, name)

    quote bind_quoted: [name: name, plug: plug, authenticator: authenticator] do
      authenticator
      |> Module.concat(name)
      |> Module.create(
        quote do
          @behaviour Plug
          @moduledoc "See `#{unquote(plug)}`."

          @impl Plug
          def init(opts), do: opts

          @impl Plug
          def call(conn, opts) do
            unquote(plug).call(conn, [{:with, unquote(authenticator)} | opts])
          end
        end,
        Macro.Env.location(__ENV__)
      )
    end
  end
end
