defmodule Chaoschat.Repo.Migrations.CreateChannels do
  use Ecto.Migration

  def change do
    create table(:channels) do
      add :name, :string
      add :description, :string
      add :server_id, references(:servers, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:channels, [:user_id])

    create index(:channels, [:server_id])
  end
end
