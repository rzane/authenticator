defmodule Authenticator.Unauthenticated do
  @moduledoc """
  A plug that requires the user to be unauthenticated. If the
  user is authenticated, the `fallback/2` function will
  be called with a reason of `:not_unauthenticated`.

  ## Examples

      plug Authenticator.Unauthenticated, with: MyAppWeb.Authenticator

  """

  @behaviour Plug

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(conn, opts) do
    authenticator = Keyword.fetch!(opts, :with)

    if authenticator.signed_in?(conn) do
      authenticator.fallback(conn, :not_unauthenticated)
    else
      conn
    end
  end
end
