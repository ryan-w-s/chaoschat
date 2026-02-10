defmodule Chaoschat.Repo do
  use Ecto.Repo,
    otp_app: :chaoschat,
    adapter: Ecto.Adapters.SQLite3
end
