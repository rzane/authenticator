defmodule Authenticator.Header do
  @moduledoc """
  A plug that authenticates a resource from the `Authorization` header. The
  header is expected to conform to the following format:

      Bearer <token>

  If the header is not present or has an invalid format, this plug won't do anything.

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
    case Plug.Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        authenticator.call(conn, token)

      _ ->
        authenticator.assign(conn)
    end
  end
end
