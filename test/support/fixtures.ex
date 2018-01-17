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
  def tokenize(_), do: :error

  @impl true
  def authenticate(_), do: :error
end
