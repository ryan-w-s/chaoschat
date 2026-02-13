defmodule Chaoschat.Servers do
  @moduledoc """
  The Servers context.
  """

  import Ecto.Query, warn: false
  alias Chaoschat.Accounts.Scope
  alias Chaoschat.Repo
  alias Chaoschat.Servers.{Server, ServerMember}

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
end
