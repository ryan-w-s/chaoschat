defmodule Chaoschat.Servers.ServerMember do
  @moduledoc """
  Schema for server memberships (join table between servers and users).
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Chaoschat.Accounts.User
  alias Chaoschat.Servers.Server

  schema "server_members" do
    field :role, :string, default: "member"

    belongs_to :server, Server
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(server_member, attrs) do
    server_member
    |> cast(attrs, [:role])
    |> validate_required([:role, :server_id, :user_id])
    |> validate_inclusion(:role, ["owner", "member"])
    |> unique_constraint([:server_id, :user_id])
  end
end
