defmodule Authenticator.Fixtures.Success do
  use Authenticator

  @impl true
  def tokenize(value), do: {:ok, value}

  @impl true
  def authenticate(value), do: {:ok, value}

  @impl true
  def fallback(conn, reason) do
    Plug.Conn.put_private(conn, :reason, reason)
  end
end

defmodule Authenticator.Fixtures.Failure do
  use Authenticator

  @impl true
  def tokenize(_), do: {:error, :tokenize}

  @impl true
  def authenticate(_), do: {:error, :authenticate}

  @impl true
  def fallback(conn, reason) do
    Plug.Conn.put_private(conn, :reason, reason)
  end
end

defmodule Authenticator.Fixtures.Token do
  defstruct [:token]
end

defmodule Authenticator.Fixtures.Accounts do
  alias Authenticators.Fixtures.Token

  def authenticate(value), do: {:ok, value.token}
  def tokenize(value), do: {:ok, %Token{token: value}}
end

defmodule Authenticator.Fixtures.Authority do
  use Authenticator

  use Authenticator.Authority,
    token_schema: Authenticator.Fixtures.Token,
    tokenization: Authenticator.Fixtures.Accounts,
    authentication: Authenticator.Fixtures.Accounts

  @impl true
  def fallback(conn, _reason) do
  end
end
