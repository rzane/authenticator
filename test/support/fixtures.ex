defmodule Authenticator.Fixtures.Success do
  use Authenticator

  @impl true
  def tokenize(value), do: {:ok, value}

  @impl true
  def authenticate(value), do: {:ok, value}
end

defmodule Authenticator.Fixtures.Failure do
  use Authenticator

  @impl true
  def tokenize(_), do: {:error, :tokenize}

  @impl true
  def authenticate(_), do: {:error, :authenticate}

  @impl true
  def fallback(conn, reason) do
    conn
    |> put_private(:reason, reason)
  end
end
