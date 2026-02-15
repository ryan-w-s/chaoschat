defmodule Chaoschat.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chaoschat.Chat` context.
  """
  import Chaoschat.AccountsFixtures
  import Chaoschat.ServersFixtures

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})
    user = attrs[:user] || user_fixture()
    scope = %Chaoschat.Accounts.Scope{user: user}

    # helper to get or create channel
    channel =
      if c = attrs[:channel] do
        c
      else
        server = attrs[:server] || server_fixture(scope)
        channel_fixture(scope, %{server_id: server.id})
      end

    attrs =
      attrs
      |> Map.delete(:user)
      |> Map.delete(:server)
      |> Map.delete(:channel)
      |> Enum.into(%{content: "some content"})

    {:ok, message} = Chaoschat.Chat.create_message(channel, user, attrs)

    message
  end
end
