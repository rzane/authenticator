# Authenticator

```elixir
defmodule MyAppWeb.Authenticator do
  use Authenticator

  import Phoenix.Controller

  alias MyApp.Repo
  alias MyApp.Accounts.User

  @impl true
  def tokenize(user) do
    {:ok, user.id}
  end

  @impl true
  def authenticate(user_id) do
    case Repo.get(User) do
      nil ->
        {:error, :not_found}

      user ->
        {:ok, user}
    end
  end

  @impl true
  def fallback(conn, :not_found) do
    conn
    |> redirect(to: login_path(conn))
  end

  def fallback(conn, :not_authenticated) do
    conn
    |> put_flash(:error, "You must be signed in.")
    |> redirect(to: root_path(conn))
  end

  def fallback(conn, :not_unauthenticated) do
    conn
    |> put_flash(:error, "You are already signed in.")
    |> redirect(to: root_path(conn))
  end
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `authenticator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:authenticator, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/authenticator](https://hexdocs.pm/authenticator).

