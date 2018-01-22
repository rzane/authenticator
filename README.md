# Authenticator

This module provides the glue for authenticating HTTP requests.

By using `Authenticator`, you'll get the following functions:

* `sign_in(conn, user)` - Sign a user in.
* `sign_out(conn)` - Sign a user out.
* `signed_in?(conn)` - Check if a user is signed in.

You'll also get the following plugs:

* `Authenticator.Session` - Authenticate a user from the session.
* `Authenticator.Header` - Authenticate a user from the `Authorization` header.
* `Authenticator.Authenticated` - Make sure a user is signed in.
* `Authenticator.Unauthenticated` - Make sure a user is *not* signed in.

## Installation

The package can be installed by adding `authenticator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:authenticator, "~> 0.1.0"}]
end
```

## Usage

To use `Authenticator`, you'll need to define the following functions:

* `tokenize(resource)` - Serialize the user into a "token" that can be stored in the session.
* `authenticate(resource)` - Given a "token", locate the user.
* `fallback(conn, reason)` - Handle authentication errors.

Here's an example implementation of an authenticator:

```elixir
# lib/my_app_web/authenticator.ex

defmodule MyAppWeb.Authenticator do
  use Authenticator

  import Phoenix.Controller
  import MyApp.Router.Helpers

  alias MyApp.Repo
  alias MyApp.Accounts.User

  @impl true
  def tokenize(user) do
    {:ok, to_string(user.id)}
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

## Plugs

All of the plugs provided by `Authenticator` expect your app's authenticator as an argument.

Make sure you use either `Authenticator.Session` or `Authenticator.Header`

```elixir
pipeline :browser do
  # snip...

  plug Authenticator.Session, MyAppWeb.Authenticator
end

pipeline :authenticated do
  plug Authenticator.Authenticated, MyAppWeb.Authenticated
end

scope "/", MyAppWeb do
  pipe_through([:browser, :authenticated])

  # declare protected routes here
end
```
