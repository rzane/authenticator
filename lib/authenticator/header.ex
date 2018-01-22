defmodule Authenticator.Header do
  @moduledoc """
  Authenticates the user from the authorization header.

  ## Examples

      plug Authenticator.Header, MyAppWeb.Authenticator

  """

  @behaviour Plug

  @impl Plug
  def init(authenticator) do
    authenticator
  end

  @impl Plug
  def call(conn, authenticator) do
    authenticator.authenticate_header(conn)
  end
end
