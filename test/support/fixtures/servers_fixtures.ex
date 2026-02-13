defmodule Chaoschat.ServersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Chaoschat.Servers` context.
  """

  alias Chaoschat.Servers

  @doc """
  Generate a server (with the creator as owner member).
  """
  def server_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        description: "some description",
        name: "some name"
      })

    {:ok, server} = Servers.create_server(scope, attrs)
    server
  end

  @doc """
  Adds a user to a server as a member.
  """
  def server_member_fixture(server, scope) do
    {:ok, member} = Servers.join_server(server, scope)
    member
  end
end
