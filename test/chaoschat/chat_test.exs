defmodule Chaoschat.ChatTest do
  use Chaoschat.DataCase

  alias Chaoschat.Chat
  import Chaoschat.ChatFixtures
  import Chaoschat.AccountsFixtures
  import Chaoschat.ServersFixtures

  describe "messages" do
    alias Chaoschat.Chat.Message

    @invalid_attrs %{content: nil}

    setup do
      user = user_fixture()
      scope = %Chaoschat.Accounts.Scope{user: user}
      server = server_fixture(scope)
      channel = channel_fixture(scope, server_id: server.id)
      %{user: user, channel: channel, server: server}
    end

    test "list_messages/2 returns messages for channel", %{user: user, channel: channel} do
      message = message_fixture(user: user, channel: channel) |> Repo.preload(:user)
      assert Chat.list_messages(channel) == [message]
    end

    test "list_messages/2 pagination orders correctly", %{user: user, channel: channel} do
      # Create messages with slight delays to ensure timestamp ordering
      m1 = message_fixture(user: user, channel: channel, content: "1") |> Repo.preload(:user)
      # Wait a bit explicitly
      :timer.sleep(100)
      m2 = message_fixture(user: user, channel: channel, content: "2") |> Repo.preload(:user)
      :timer.sleep(100)
      m3 = message_fixture(user: user, channel: channel, content: "3") |> Repo.preload(:user)

      # Default: newest first (desc) -> reversed to [oldest, ..., newest] (asc)
      # Wait, my implementation reverses it.
      # Implementation: Repo.all(desc) |> Enum.reverse()
      # Repo.all(desc) -> [m3, m2, m1]
      # Enum.reverse -> [m1, m2, m3]
      assert Chat.list_messages(channel) == [m1, m2, m3]

      # Limit 2
      # Repo.all(desc, limit: 2) -> [m3, m2]
      # Enum.reverse -> [m2, m3]
      assert Chat.list_messages(channel, limit: 2) == [m2, m3]
    end

    test "list_messages/2 with cursor", %{user: user, channel: channel} do
      m1 = message_fixture(user: user, channel: channel, content: "1")
      :timer.sleep(100)
      m2 = message_fixture(user: user, channel: channel, content: "2")
      :timer.sleep(100)
      m3 = message_fixture(user: user, channel: channel, content: "3")

      # Latest page (limit 1) -> [m3]
      # Repo.all(limit: 1) -> [m3]. Reverse -> [m3]
      [last_msg] = Chat.list_messages(channel, limit: 1)
      assert last_msg.id == m3.id

      # Fetch before m3
      # Cursor = m3.
      # Query: where inserted_at < m3.inserted_at. Order desc. Limit 1.
      # Returns [m2]. Reverse -> [m2].
      [middle_msg] = Chat.list_messages(channel, limit: 1, before: last_msg)
      assert middle_msg.id == m2.id

      # Fetch before m2
      [first_msg] = Chat.list_messages(channel, limit: 1, before: middle_msg)
      assert first_msg.id == m1.id

      # Fetch before m1 (should be empty)
      assert Chat.list_messages(channel, limit: 1, before: first_msg) == []
    end

    test "create_message/3 with valid data creates a message", %{user: user, channel: channel} do
      valid_attrs = %{content: "some content"}

      assert {:ok, %Message{} = message} = Chat.create_message(channel, user, valid_attrs)
      assert message.content == "some content"
      assert message.channel_id == channel.id
      assert message.user_id == user.id
    end

    test "create_message/3 with invalid data returns error changeset", %{
      user: user,
      channel: channel
    } do
      assert {:error, %Ecto.Changeset{}} = Chat.create_message(channel, user, @invalid_attrs)
    end

    test "update_message/2 with valid data updates the message", %{user: user, channel: channel} do
      message = message_fixture(user: user, channel: channel)
      update_attrs = %{content: "some updated content"}

      assert {:ok, %Message{} = message} = Chat.update_message(message, update_attrs)
      assert message.content == "some updated content"
    end

    test "update_message/2 with invalid data returns error changeset", %{
      user: user,
      channel: channel
    } do
      message = message_fixture(user: user, channel: channel)
      assert {:error, %Ecto.Changeset{}} = Chat.update_message(message, @invalid_attrs)
      assert message.content == Chat.get_message!(message.id).content
    end

    test "delete_message/1 deletes the message", %{user: user, channel: channel} do
      message = message_fixture(user: user, channel: channel)
      assert {:ok, %Message{}} = Chat.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset", %{user: user, channel: channel} do
      message = message_fixture(user: user, channel: channel)
      assert %Ecto.Changeset{} = Chat.change_message(message)
    end
  end
end
