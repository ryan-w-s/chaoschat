defmodule Chaoschat.Chat.Message do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :content, :string
    belongs_to :channel, Chaoschat.Servers.Channel
    belongs_to :user, Chaoschat.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :channel_id, :user_id])
    |> validate_required([:content])
  end
end
