defmodule Authenticator.Session do
  @moduledoc """
  Authenticates the user from the session.

  ## Examples

      plug Authenticator.Session, MyAppWeb.Authenticator

  """

  @behaviour Plug

  @impl true
  def init(authenticator) do
    authenticator
  end

  @impl Plug
  def call(conn, authenticator) do
    case authenticator.get_session(conn) do
      nil ->
        authenticator.assign(conn)

      token ->
        authenticator.call(conn, token)
    end
  end
end
