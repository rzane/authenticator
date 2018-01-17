defmodule Authenticator.ConnCase do
  use ExUnit.CaseTemplate

  @secret String.duplicate("abcdef0123456789", 8)

  @default_opts [
    store: :cookie,
    key: "foobar",
    encryption_salt: "encrypted cookie salt",
    signing_salt: "signing salt",
    log: false
  ]

  @signing_opts Plug.Session.init(@default_opts)

  using do
    quote do
      import Plug.Conn
    end
  end

  setup do
    [conn: build_conn()]
  end

  defp build_conn do
    %Plug.Conn{secret_key_base: @secret}
    |> Plug.Session.call(@signing_opts)
    |> Plug.Conn.fetch_session()
  end
end
