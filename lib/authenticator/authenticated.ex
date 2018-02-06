defmodule Authenticator.Authenticated do
  @moduledoc """
  A plug that requires the user to be authenticated. If the
  user is not authenticated, the `fallback/2` function will
  be called with a reason of `:not_authenticated`.

  ## Examples

      plug Authenticator.Authenticated, with: MyAppWeb.Authenticator

  """

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, opts) do
    authenticator = Keyword.fetch!(opts, :with)

    if authenticator.signed_in?(conn) do
      conn
    else
      authenticator.fallback(conn, :not_authenticated)
    end
  end
end
