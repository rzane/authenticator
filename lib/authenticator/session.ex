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
    authenticator.authenticate_session(conn)
  end
end
