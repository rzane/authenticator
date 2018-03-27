defmodule Authenticator.Fixtures.Fallback do
  def call(conn, {:error, reason}) do
    Plug.Conn.put_private(conn, :reason, reason)
  end
end

defmodule Authenticator.Fixtures.Success do
  use Authenticator, fallback: Authenticator.Fixtures.Fallback

  @impl true
  def tokenize(value), do: {:ok, value}

  @impl true
  def authenticate(value), do: {:ok, value}
end

defmodule Authenticator.Fixtures.Failure do
  use Authenticator, fallback: Authenticator.Fixtures.Fallback

  @impl true
  def tokenize(_), do: {:error, :tokenize}

  @impl true
  def authenticate(_), do: {:error, :authenticate}
end
