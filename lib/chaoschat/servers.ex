defmodule Chaoschat.Servers do
  @moduledoc """
  The Servers context.
  """

  import Ecto.Query, warn: false
  alias Chaoschat.Accounts.Scope
  alias Chaoschat.Repo
  alias Chaoschat.Servers.{Channel, Server, ServerMember}

  @doc """
  Subscribes to scoped notifications about any server changes.

  The broadcasted messages match the pattern:

    * {:created, %Server{}}
    * {:updated, %Server{}}
    * {:deleted, %Server{}}

  """
  def subscribe_servers(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Chaoschat.PubSub, "user:#{key}:servers")
  end

  defp broadcast_server(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Chaoschat.PubSub, "user:#{key}:servers", message)
  end

  @doc """
  Returns the list of servers owned by the scoped user.

  ## Examples

      iex> list_servers(scope)
      [%Server{}, ...]

  """
  def list_servers(%Scope{} = scope) do
    Repo.all_by(Server, user_id: scope.user.id)
  end

  @doc """
  Returns all servers the given user is a member of.
  """
  def list_joined_servers(%Scope{} = scope) do
    from(s in Server,
      join: sm in ServerMember,
      on: sm.server_id == s.id,
      where: sm.user_id == ^scope.user.id,
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Returns all servers (for discovery).
  """
  def list_all_servers do
    Server
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Gets a single server.

  Raises `Ecto.NoResultsError` if the Server does not exist.

  ## Examples

      iex> get_server!(scope, 123)
      %Server{}

      iex> get_server!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_server!(%Scope{} = scope, id) do
    Repo.get_by!(Server, id: id, user_id: scope.user.id)
  end

  @doc """
  Gets a single server by id (no scope restriction), preloading associations.
  """
  def get_server!(id) do
    Server
    |> preload([:user, server_members: :user])
    |> Repo.get!(id)
  end

  @doc """
  Creates a server and auto-adds the creator as an "owner" member.

  ## Examples

      iex> create_server(scope, %{field: value})
      {:ok, %Server{}}

      iex> create_server(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_server(%Scope{} = scope, attrs) do
    Repo.transact(fn ->
      with {:ok, %Server{} = server} <-
             %Server{}
             |> Server.changeset(attrs, scope)
             |> Repo.insert(),
           {:ok, _member} <-
             %ServerMember{server_id: server.id, user_id: scope.user.id, role: "owner"}
             |> Repo.insert() do
        broadcast_server(scope, {:created, server})
        {:ok, server}
      end
    end)
  end

  @doc """
  Updates a server.

  ## Examples

      iex> update_server(scope, server, %{field: new_value})
      {:ok, %Server{}}

      iex> update_server(scope, server, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_server(%Scope{} = scope, %Server{} = server, attrs) do
    true = server.user_id == scope.user.id

    with {:ok, server = %Server{}} <-
           server
           |> Server.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_server(scope, {:updated, server})
      {:ok, server}
    end
  end

  @doc """
  Deletes a server.

  ## Examples

      iex> delete_server(scope, server)
      {:ok, %Server{}}

      iex> delete_server(scope, server)
      {:error, %Ecto.Changeset{}}

  """
  def delete_server(%Scope{} = scope, %Server{} = server) do
    true = server.user_id == scope.user.id

    with {:ok, server = %Server{}} <-
           Repo.delete(server) do
      broadcast_server(scope, {:deleted, server})
      {:ok, server}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking server changes.

  ## Examples

      iex> change_server(scope, server)
      %Ecto.Changeset{data: %Server{}}

  """
  def change_server(%Scope{} = scope, %Server{} = server, attrs \\ %{}) do
    true = server.user_id == scope.user.id

    Server.changeset(server, attrs, scope)
  end

  # --- Membership ---

  @doc """
  Adds a user as a member of a server.
  """
  def join_server(%Server{} = server, %Scope{} = scope) do
    %ServerMember{server_id: server.id, user_id: scope.user.id}
    |> ServerMember.changeset(%{role: "member"})
    |> Repo.insert()
  end

  @doc """
  Removes a user from a server.
  """
  def leave_server(%Server{} = server, %Scope{} = scope) do
    member =
      Repo.get_by(ServerMember, server_id: server.id, user_id: scope.user.id)

    if member && member.role != "owner" do
      Repo.delete(member)
    else
      {:error, :cannot_leave}
    end
  end

  @doc """
  Checks if the user is a member of the server.
  """
  def member?(%Server{} = server, %Scope{} = scope) do
    from(sm in ServerMember,
      where: sm.server_id == ^server.id and sm.user_id == ^scope.user.id
    )
    |> Repo.exists?()
  end

  @doc """
  Returns the member count for a server.
  """
  def member_count(%Server{} = server) do
    from(sm in ServerMember, where: sm.server_id == ^server.id)
    |> Repo.aggregate(:count)
  end

  alias Chaoschat.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any channel changes.

  The broadcasted messages match the pattern:

    * {:created, %Channel{}}
    * {:updated, %Channel{}}
    * {:deleted, %Channel{}}

  """
  def subscribe_channels(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Chaoschat.PubSub, "user:#{key}:channels")
  end

  defp broadcast_channel(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Chaoschat.PubSub, "user:#{key}:channels", message)
  end

  @doc """
  Returns the list of channels.

  ## Examples

      iex> list_channels(scope)
      [%Channel{}, ...]

  """
  def list_channels(%Scope{} = _scope, server_id) do
    from(c in Channel, where: c.server_id == ^server_id)
    |> Repo.all()
  end

  @doc """
  Gets a single channel.

  Raises `Ecto.NoResultsError` if the Channel does not exist.

  ## Examples

      iex> get_channel!(scope, 123)
      %Channel{}

      iex> get_channel!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_channel!(%Scope{} = scope, id) do
    Repo.get_by!(Channel, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a channel.

  ## Examples

      iex> create_channel(scope, %{field: value})
      {:ok, %Channel{}}

      iex> create_channel(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_channel(%Scope{} = scope, attrs) do
    with {:ok, channel = %Channel{}} <-
           %Channel{}
           |> Channel.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_channel(scope, {:created, channel})
      {:ok, channel}
    end
  end

  @doc """
  Updates a channel.

  ## Examples

      iex> update_channel(scope, channel, %{field: new_value})
      {:ok, %Channel{}}

      iex> update_channel(scope, channel, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_channel(%Scope{} = scope, %Channel{} = channel, attrs) do
    true = channel.user_id == scope.user.id

    with {:ok, channel = %Channel{}} <-
           channel
           |> Channel.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_channel(scope, {:updated, channel})
      {:ok, channel}
    end
  end

  @doc """
  Deletes a channel.

  ## Examples

      iex> delete_channel(scope, channel)
      {:ok, %Channel{}}

      iex> delete_channel(scope, channel)
      {:error, %Ecto.Changeset{}}

  """
  def delete_channel(%Scope{} = scope, %Channel{} = channel) do
    true = channel.user_id == scope.user.id

    with {:ok, channel = %Channel{}} <-
           Repo.delete(channel) do
      broadcast_channel(scope, {:deleted, channel})
      {:ok, channel}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking channel changes.

  ## Examples

      iex> change_channel(scope, channel)
      %Ecto.Changeset{data: %Channel{}}

  """
  def change_channel(%Scope{} = scope, %Channel{} = channel, attrs \\ %{}) do
    true = channel.user_id == scope.user.id

    Channel.changeset(channel, attrs, scope)
  end
end
