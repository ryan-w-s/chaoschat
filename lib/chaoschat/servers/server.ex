defmodule Chaoschat.Servers.Server do
  @moduledoc """
  Schema for chat servers.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Chaoschat.Accounts.User
  alias Chaoschat.Servers.ServerMember

  schema "servers" do
    field :name, :string
    field :description, :string

    belongs_to :user, User
    has_many :server_members, ServerMember
    has_many :members, through: [:server_members, :user]
    has_many :channels, Chaoschat.Servers.Channel

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(server, attrs, user_scope) do
    server
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description, max: 500)
    |> put_change(:user_id, user_scope.user.id)
  end
end
