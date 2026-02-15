defmodule ChaoschatWeb.ServerLive.Show do
  use ChaoschatWeb, :live_view

  alias Chaoschat.Servers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@server.name}
        <:subtitle :if={@server.description}>{@server.description}</:subtitle>
        <:actions>
          <.button navigate={~p"/servers"}>
            <.icon name="hero-arrow-left" /> Back
          </.button>
          <.button
            :if={@is_owner}
            variant="primary"
            navigate={~p"/servers/#{@server}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Edit
          </.button>
          <.button
            :if={@is_owner}
            phx-click="delete"
            data-confirm="Are you sure you want to delete this server? This cannot be undone."
            class="bg-red-600 text-white hover:bg-red-700"
          >
            <.icon name="hero-trash" /> Delete
          </.button>
        </:actions>
      </.header>

      <div class="mt-8 grid gap-8 lg:grid-cols-3">
        <div class="lg:col-span-2 space-y-6">
          <div class="rounded-xl border border-zinc-200 bg-white p-6 dark:border-zinc-700 dark:bg-zinc-800">
            <h2 class="text-sm font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
              About
            </h2>
            <p class="mt-2 text-zinc-700 dark:text-zinc-300">
              {if @server.description, do: @server.description, else: "No description provided."}
            </p>
            <div class="mt-4 text-xs text-zinc-500 dark:text-zinc-500">
              Created by {@server.user.email}
            </div>
          </div>
        </div>

        <div class="space-y-6">
          <div class="rounded-xl border border-zinc-200 bg-white p-6 dark:border-zinc-700 dark:bg-zinc-800">
            <div class="flex items-center justify-between">
              <h2 class="text-sm font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
                Channels
              </h2>
              <.button
                :if={@is_owner}
                navigate={~p"/servers/#{@server}/channels/new"}
                class="text-xs bg-indigo-600 text-white hover:bg-indigo-700"
              >
                New Channel
              </.button>
            </div>
            <ul
              id="channels"
              phx-update="stream"
              class="mt-4 divide-y divide-zinc-100 dark:divide-zinc-700"
            >
              <li
                :for={{id, channel} <- @streams.channels}
                id={id}
                class="flex items-center justify-between gap-3 py-2.5"
              >
                <div>
                  <p class="font-medium text-zinc-900 dark:text-zinc-100">
                    <.link
                      navigate={~p"/servers/#{@server}/channels/#{channel}"}
                      class="hover:underline"
                    >
                      #{channel.name}
                    </.link>
                  </p>
                  <p class="text-xs text-zinc-500">{channel.description}</p>
                </div>
                <div :if={@is_owner} class="flex items-center gap-2">
                  <.link
                    navigate={~p"/servers/#{@server}/channels/#{channel}/edit"}
                    class="text-xs text-zinc-500 hover:text-zinc-700"
                  >
                    Edit
                  </.link>
                </div>
              </li>
            </ul>
            <div
              :if={@channels_count == 0}
              class="mt-4 text-sm text-zinc-500 italic"
            >
              No channels yet.
            </div>
          </div>

          <div class="rounded-xl border border-zinc-200 bg-white p-6 dark:border-zinc-700 dark:bg-zinc-800">
            <div class="flex items-center justify-between">
              <h2 class="text-sm font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
                Members ({length(@server.server_members)})
              </h2>
              <%= if @is_member do %>
                <.button
                  :if={!@is_owner}
                  phx-click="leave"
                  id="leave-btn"
                  class="text-xs bg-zinc-100 text-zinc-700 hover:bg-zinc-200 dark:bg-zinc-700 dark:text-zinc-300"
                >
                  Leave
                </.button>
              <% else %>
                <.button
                  phx-click="join"
                  id="join-btn"
                  class="text-xs bg-indigo-600 text-white hover:bg-indigo-700"
                >
                  Join Server
                </.button>
              <% end %>
            </div>
            <ul class="mt-4 divide-y divide-zinc-100 dark:divide-zinc-700">
              <li
                :for={member <- @server.server_members}
                class="flex items-center gap-3 py-2.5"
              >
                <div class="flex h-8 w-8 items-center justify-center rounded-full bg-indigo-100 text-sm font-medium text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-400">
                  {String.first(member.user.email) |> String.upcase()}
                </div>
                <div class="flex-1 min-w-0">
                  <p class="truncate text-sm text-zinc-900 dark:text-zinc-100">
                    {member.user.email}
                  </p>
                </div>
                <span class={[
                  "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium",
                  if(member.role == "owner",
                    do: "bg-indigo-50 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400",
                    else: "bg-zinc-100 text-zinc-600 dark:bg-zinc-700 dark:text-zinc-400"
                  )
                ]}>
                  {member.role}
                </span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    server = Servers.get_server!(id)

    if connected?(socket) do
      Servers.subscribe_servers(socket.assigns.current_scope)
      Servers.subscribe_channels(socket.assigns.current_scope)
    end

    channels = Servers.list_channels(socket.assigns.current_scope, server.id)

    {:ok,
     socket
     |> assign_server(server)
     |> assign(:channels_count, length(channels))
     |> stream(:channels, channels)}
  end

  @impl true
  def handle_event("join", _params, socket) do
    case Servers.join_server(socket.assigns.server, socket.assigns.current_scope) do
      {:ok, _member} ->
        server = Servers.get_server!(socket.assigns.server.id)

        {:noreply,
         socket
         |> put_flash(:info, "You joined the server!")
         |> assign_server(server)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not join server.")}
    end
  end

  def handle_event("leave", _params, socket) do
    case Servers.leave_server(socket.assigns.server, socket.assigns.current_scope) do
      {:ok, _member} ->
        server = Servers.get_server!(socket.assigns.server.id)

        {:noreply,
         socket
         |> put_flash(:info, "You left the server.")
         |> assign_server(server)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not leave server.")}
    end
  end

  def handle_event("delete", _params, socket) do
    {:ok, _} = Servers.delete_server(socket.assigns.current_scope, socket.assigns.server)

    {:noreply,
     socket
     |> put_flash(:info, "Server deleted.")
     |> push_navigate(to: ~p"/servers")}
  end

  @impl true
  def handle_info(
        {:updated, %Chaoschat.Servers.Server{id: id}},
        %{assigns: %{server: %{id: id}}} = socket
      ) do
    server = Servers.get_server!(id)
    {:noreply, assign_server(socket, server)}
  end

  def handle_info(
        {:deleted, %Chaoschat.Servers.Server{id: id}},
        %{assigns: %{server: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "This server was deleted.")
     |> push_navigate(to: ~p"/servers")}
  end

  def handle_info({type, %Chaoschat.Servers.Channel{} = channel}, socket)
      when type in [:created, :updated, :deleted] do
    # Only update if channel belongs to this server
    if channel.server_id == socket.assigns.server.id do
      case type do
        :deleted -> {:noreply, stream_delete(socket, :channels, channel)}
        _ -> {:noreply, stream_insert(socket, :channels, channel)}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_info({type, %Chaoschat.Servers.Server{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end

  defp assign_server(socket, server) do
    scope = socket.assigns.current_scope
    is_member = Servers.member?(server, scope)
    is_owner = server.user_id == scope.user.id

    socket
    |> assign(:page_title, server.name)
    |> assign(:server, server)
    |> assign(:is_member, is_member)
    |> assign(:is_owner, is_owner)
  end
end
