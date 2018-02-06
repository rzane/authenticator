defmodule Authenticator.Authority do
  @moduledoc """
  This module provides a shortcut for using `Authenticator` with `Authority`.
  """

  defmacro __using__(opts) do
    quote location: :keep do
      @token_schema Keyword.fetch!(unquote(opts), :token_schema)
      @tokenization Keyword.fetch!(unquote(opts), :tokenization)
      @authentication Keyword.fetch!(unquote(opts), :authentication)

      @impl true
      def tokenize(user) do
        with {:ok, token} <- @tokenization.tokenize(user) do
          {:ok, token.token}
        end
      end

      @impl true
      def authenticate(token) do
        @authentication.authenticate(%@token_schema{token: token})
      end
    end
  end
end