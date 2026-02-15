defmodule Chaoschat.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Chaoschat.Repo

  alias Chaoschat.Accounts.User
  alias Chaoschat.Chat.Message
  alias Chaoschat.Servers.Channel

  @doc """
  Returns the list of messages for a channel.

  ## Options

    * `:limit` - The number of messages to return. Defaults to 50.
    * `:before` - The cursor (Message struct) to fetch messages before (older than).

  """
  def list_messages(%Channel{} = channel, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    cursor = Keyword.get(opts, :before)

    query =
      from m in Message,
        where: m.channel_id == ^channel.id,
        order_by: [desc: m.inserted_at, desc: m.id],
        limit: ^limit,
        preload: [:user]

    query =
      if cursor do
        # Keyset pagination: fetched items older than the cursor
        where(
          query,
          [m],
          m.inserted_at < ^cursor.inserted_at or
            (m.inserted_at == ^cursor.inserted_at and m.id < ^cursor.id)
        )
      else
        query
      end

    Repo.all(query)
    # We fetch descending (newest first) to get the "latest" chunk,
    # but for the UI it's often convenient to have them ascending (oldest to newest).
    |> Enum.reverse()
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.
  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a message.
  """
  def create_message(%Channel{} = channel, %User{} = user, attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Ecto.Changeset.put_change(:channel_id, channel.id)
    |> Ecto.Changeset.put_change(:user_id, user.id)
    |> Repo.insert()
  end

  @doc """
  Updates a message.
  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.
  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.
  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
