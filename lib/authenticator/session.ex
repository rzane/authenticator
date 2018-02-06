defmodule Authenticator.Session do
  @moduledoc """
  Authenticates the user from the session.

  ## Examples

      plug Authenticator.Session, with: MyAppWeb.Authenticator

  """

  @behaviour Plug

  @impl true
  def init(opts) do
    opts
  end

  @impl Plug
  def call(conn, opts) do
    authenticator = Keyword.fetch!(opts, :with)

    case authenticator.get_session(conn) do
      nil ->
        authenticator.assign(conn)

      token ->
        authenticator.call(conn, token)
    end
  end
end
