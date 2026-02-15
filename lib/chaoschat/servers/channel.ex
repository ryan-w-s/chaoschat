defmodule Chaoschat.Servers.Channel do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "channels" do
    field :name, :string
    field :description, :string
    belongs_to :server, Chaoschat.Servers.Server
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(channel, attrs, user_scope) do
    channel
    |> cast(attrs, [:name, :description, :server_id])
    |> validate_required([:name, :description, :server_id])
    |> put_change(:user_id, user_scope.user.id)
  end
end
