defmodule Chaoschat.Repo.Migrations.CreateServers do
  use Ecto.Migration

  def change do
    create table(:servers) do
      add :name, :string, null: false
      add :description, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:servers, [:user_id])

    create table(:server_members) do
      add :role, :string, null: false, default: "member"
      add :server_id, references(:servers, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:server_members, [:server_id])
    create index(:server_members, [:user_id])
    create unique_index(:server_members, [:server_id, :user_id])
  end
end
