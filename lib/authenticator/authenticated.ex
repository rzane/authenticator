defmodule Authenticator.Authenticated do
  @moduledoc """
  A plug that requires the user to be authenticated. If the
  user is not authenticated, the `fallback/2` function will
  be called with a reason of `:not_authenticated`.

  ## Examples

      plug Authenticator.Authenticated, MyAppWeb.Authenticator

  """

  @behaviour Plug

  @impl Plug
  def init(authenticator) do
    authenticator
  end

  @impl Plug
  def call(conn, authenticator) do
    if authenticator.authenticated?(conn) do
      conn
    else
      authenticator.fallback(conn, :not_authenticated)
    end
  end
end
