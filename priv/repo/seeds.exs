# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Chaoschat.Repo
alias Chaoschat.Accounts.User
alias Chaoschat.Servers.{Server, ServerMember}

password = "password1234"
hashed_password = Pbkdf2.hash_pwd_salt(password)
now = DateTime.utc_now(:second)

users_data = [
  %{
    email: "alice@example.com",
    server_name: "Alice's Hangout",
    server_desc: "A chill place to chat"
  },
  %{
    email: "bob@example.com",
    server_name: "Bob's Workshop",
    server_desc: "Building cool stuff together"
  },
  %{email: "charlie@example.com", server_name: "Charlie's Lounge", server_desc: "Come hang out!"},
  %{
    email: "diana@example.com",
    server_name: "Diana's Den",
    server_desc: "Cozy corner of the internet"
  },
  %{email: "eve@example.com", server_name: "Eve's Arena", server_desc: "Let the games begin"}
]

for data <- users_data do
  # Insert user (skip if already exists)
  user =
    case Repo.get_by(User, email: data.email) do
      nil ->
        Repo.insert!(%User{
          email: data.email,
          hashed_password: hashed_password,
          confirmed_at: now,
          inserted_at: now,
          updated_at: now
        })

      existing ->
        existing
    end

  # Create server owned by this user (skip if already exists)
  server =
    case Repo.get_by(Server, name: data.server_name) do
      nil ->
        Repo.insert!(%Server{
          name: data.server_name,
          description: data.server_desc,
          user_id: user.id,
          inserted_at: now,
          updated_at: now
        })

      existing ->
        existing
    end

  # Add user as owner member (skip if already exists)
  case Repo.get_by(ServerMember, server_id: server.id, user_id: user.id) do
    nil ->
      Repo.insert!(%ServerMember{
        server_id: server.id,
        user_id: user.id,
        role: "owner",
        inserted_at: now,
        updated_at: now
      })

    _existing ->
      :ok
  end
end

IO.puts("\n✅ Seeded 5 users (password: #{password})")

IO.puts(
  "   alice@example.com | bob@example.com | charlie@example.com | diana@example.com | eve@example.com"
)
