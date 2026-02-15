defmodule Chaoschat.ServersTest do
  use Chaoschat.DataCase

  alias Chaoschat.Servers

  describe "servers" do
    alias Chaoschat.Servers.Server

    import Chaoschat.AccountsFixtures, only: [user_scope_fixture: 0]
    import Chaoschat.ServersFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_servers/1 returns all scoped servers" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      server = server_fixture(scope)
      other_server = server_fixture(other_scope)
      assert Servers.list_servers(scope) == [server]
      assert Servers.list_servers(other_scope) == [other_server]
    end

    test "list_all_servers/0 returns all servers" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      server = server_fixture(scope)
      other_server = server_fixture(other_scope)
      all = Servers.list_all_servers()
      assert Enum.any?(all, &(&1.id == server.id))
      assert Enum.any?(all, &(&1.id == other_server.id))
    end

    test "get_server!/2 returns the server with given id" do
      scope = user_scope_fixture()
      server = server_fixture(scope)
      other_scope = user_scope_fixture()
      assert Servers.get_server!(scope, server.id) == server
      assert_raise Ecto.NoResultsError, fn -> Servers.get_server!(other_scope, server.id) end
    end

    test "get_server!/1 returns the server preloaded" do
      scope = user_scope_fixture()
      server = server_fixture(scope)
      loaded = Servers.get_server!(server.id)
      assert loaded.id == server.id
      assert loaded.user.id == scope.user.id
      assert length(loaded.server_members) == 1
    end

    test "create_server/2 with valid data creates a server and owner membership" do
      valid_attrs = %{name: "some name", description: "some description"}
      scope = user_scope_fixture()

      assert {:ok, %Server{} = server} = Servers.create_server(scope, valid_attrs)
      assert server.name == "some name"
      assert server.description == "some description"
      assert server.user_id == scope.user.id
      assert Servers.member?(server, scope)
    end

    test "create_server/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Servers.create_server(scope, @invalid_attrs)
    end

    test "update_server/3 with valid data updates the server" do
      scope = user_scope_fixture()
      server = server_fixture(scope)
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Server{} = server} = Servers.update_server(scope, server, update_attrs)
      assert server.name == "some updated name"
      assert server.description == "some updated description"
    end

    test "update_server/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      server = server_fixture(scope)

      assert_raise MatchError, fn ->
        Servers.update_server(other_scope, server, %{})
      end
    end

    test "update_server/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      server = server_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Servers.update_server(scope, server, @invalid_attrs)
      assert server == Servers.get_server!(scope, server.id)
    end

    test "delete_server/2 deletes the server" do
      scope = user_scope_fixture()
      server = server_fixture(scope)
      assert {:ok, %Server{}} = Servers.delete_server(scope, server)
      assert_raise Ecto.NoResultsError, fn -> Servers.get_server!(scope, server.id) end
    end

    test "delete_server/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      server = server_fixture(scope)
      assert_raise MatchError, fn -> Servers.delete_server(other_scope, server) end
    end

    test "change_server/2 returns a server changeset" do
      scope = user_scope_fixture()
      server = server_fixture(scope)
      assert %Ecto.Changeset{} = Servers.change_server(scope, server)
    end
  end

  describe "membership" do
    import Chaoschat.AccountsFixtures, only: [user_scope_fixture: 0]
    import Chaoschat.ServersFixtures

    test "join_server/2 adds user as member" do
      owner_scope = user_scope_fixture()
      joiner_scope = user_scope_fixture()
      server = server_fixture(owner_scope)

      refute Servers.member?(server, joiner_scope)
      {:ok, _member} = Servers.join_server(server, joiner_scope)
      assert Servers.member?(server, joiner_scope)
    end

    test "join_server/2 cannot join twice" do
      owner_scope = user_scope_fixture()
      joiner_scope = user_scope_fixture()
      server = server_fixture(owner_scope)

      {:ok, _member} = Servers.join_server(server, joiner_scope)
      assert {:error, _changeset} = Servers.join_server(server, joiner_scope)
    end

    test "leave_server/2 removes member" do
      owner_scope = user_scope_fixture()
      joiner_scope = user_scope_fixture()
      server = server_fixture(owner_scope)

      {:ok, _member} = Servers.join_server(server, joiner_scope)
      assert Servers.member?(server, joiner_scope)

      {:ok, _member} = Servers.leave_server(server, joiner_scope)
      refute Servers.member?(server, joiner_scope)
    end

    test "leave_server/2 owner cannot leave" do
      owner_scope = user_scope_fixture()
      server = server_fixture(owner_scope)

      assert {:error, :cannot_leave} = Servers.leave_server(server, owner_scope)
    end

    test "member_count/1 returns correct count" do
      owner_scope = user_scope_fixture()
      joiner_scope = user_scope_fixture()
      server = server_fixture(owner_scope)

      assert Servers.member_count(server) == 1
      {:ok, _} = Servers.join_server(server, joiner_scope)
      assert Servers.member_count(server) == 2
    end

    test "list_joined_servers/1 returns servers user is member of" do
      owner_scope = user_scope_fixture()
      joiner_scope = user_scope_fixture()
      server = server_fixture(owner_scope)

      assert Servers.list_joined_servers(joiner_scope) == []
      {:ok, _} = Servers.join_server(server, joiner_scope)
      joined = Servers.list_joined_servers(joiner_scope)
      assert length(joined) == 1
      assert hd(joined).id == server.id
    end
  end

  describe "channels" do
    alias Chaoschat.Servers.Channel

    import Chaoschat.AccountsFixtures, only: [user_scope_fixture: 0]
    import Chaoschat.ServersFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_channels/1 returns all scoped channels" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      channel = channel_fixture(scope)
      other_channel = channel_fixture(other_scope)
      assert Servers.list_channels(scope, channel.server_id) == [channel]
      assert Servers.list_channels(other_scope, other_channel.server_id) == [other_channel]
    end

    test "get_channel!/2 returns the channel with given id" do
      scope = user_scope_fixture()
      channel = channel_fixture(scope)
      other_scope = user_scope_fixture()
      assert Servers.get_channel!(scope, channel.id) == channel
      assert_raise Ecto.NoResultsError, fn -> Servers.get_channel!(other_scope, channel.id) end
    end

    test "create_channel/2 with valid data creates a channel" do
      scope = user_scope_fixture()
      server = server_fixture(scope)
      valid_attrs = %{name: "some name", description: "some description", server_id: server.id}

      assert {:ok, %Channel{} = channel} = Servers.create_channel(scope, valid_attrs)
      assert channel.name == "some name"
      assert channel.description == "some description"
      assert channel.user_id == scope.user.id
    end

    test "create_channel/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      server = server_fixture(scope)

      # Invalid attrs missing required fields, but we should provide server_id if we want to test other validations,
      # or just test that it fails. @invalid_attrs has nils.
      # If create_channel requires server_id, and we don't provide it, it fails.
      # But @invalid_attrs = %{name: nil, description: nil}.
      # Creating with invalid attrs (even if server_id was present) should fail.
      # Let's add server_id to be safe? Or just assert error.
      # The test expects error changeset.
      assert {:error, %Ecto.Changeset{}} =
               Servers.create_channel(scope, Map.put(@invalid_attrs, :server_id, server.id))
    end

    test "update_channel/3 with valid data updates the channel" do
      scope = user_scope_fixture()
      channel = channel_fixture(scope)
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Channel{} = channel} = Servers.update_channel(scope, channel, update_attrs)
      assert channel.name == "some updated name"
      assert channel.description == "some updated description"
    end

    test "update_channel/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      channel = channel_fixture(scope)

      assert_raise MatchError, fn ->
        Servers.update_channel(other_scope, channel, %{})
      end
    end

    test "update_channel/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      channel = channel_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Servers.update_channel(scope, channel, @invalid_attrs)
      assert channel == Servers.get_channel!(scope, channel.id)
    end

    test "delete_channel/2 deletes the channel" do
      scope = user_scope_fixture()
      channel = channel_fixture(scope)
      assert {:ok, %Channel{}} = Servers.delete_channel(scope, channel)
      assert_raise Ecto.NoResultsError, fn -> Servers.get_channel!(scope, channel.id) end
    end

    test "delete_channel/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      channel = channel_fixture(scope)
      assert_raise MatchError, fn -> Servers.delete_channel(other_scope, channel) end
    end

    test "change_channel/2 returns a channel changeset" do
      scope = user_scope_fixture()
      channel = channel_fixture(scope)
      assert %Ecto.Changeset{} = Servers.change_channel(scope, channel)
    end
  end
end
