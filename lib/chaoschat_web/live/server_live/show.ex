defmodule ChaoschatWeb.ServerLive.Show do
  use ChaoschatWeb, :live_view

  alias Chaoschat.Servers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      joined_servers={assigns[:joined_servers]}
    >
      <div class="flex h-full w-full">
        <!-- Context Sidebar (Middle pane: Channels) -->
        <div class="w-60 flex-shrink-0 bg-zinc-50 dark:bg-[#2B2D31] flex flex-col overflow-hidden">
          <!-- Sidebar Header (Server Name) -->
          <header class="h-12 flex items-center justify-between px-4 font-semibold shadow-sm text-zinc-900 dark:text-zinc-100 border-b border-zinc-200 dark:border-zinc-800 shrink-0 transition hover:bg-zinc-200/50 dark:hover:bg-zinc-700/50 cursor-pointer">
            <span class="truncate">{@server.name}</span>
            <.icon name="hero-chevron-down" class="h-4 w-4 text-zinc-500" />
          </header>

          <div class="p-3 flex-1 overflow-y-auto hide-scrollbar">
            <div class="flex items-center justify-between mb-1 px-1 group">
              <h2 class="text-[11px] font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400 group-hover:text-zinc-600 dark:group-hover:text-zinc-300 transition-colors">
                Channels
              </h2>
              <.link
                :if={@is_owner}
                navigate={~p"/servers/#{@server}/channels/new"}
                class="text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200"
              >
                <.icon name="hero-plus" class="h-4 w-4" />
              </.link>
            </div>

            <ul id="channels" phx-update="stream" class="space-y-0.5">
              <li :for={{id, channel} <- @streams.channels} id={id}>
                <.link
                  navigate={~p"/servers/#{@server}/channels/#{channel}"}
                  class="flex items-center gap-2 px-2 py-1.5 rounded-md text-zinc-600 hover:bg-zinc-200 hover:text-zinc-900 transition-colors dark:text-zinc-400 dark:hover:bg-[#3F4147] dark:hover:text-zinc-100 font-medium group"
                >
                  <.icon name="hero-hashtag" class="h-5 w-5 opacity-50 group-hover:opacity-100" />
                  <span class="truncate flex-1">{channel.name}</span>
                  <.link
                    :if={@is_owner}
                    navigate={~p"/servers/#{@server}/channels/#{channel}/edit"}
                    class="opacity-0 group-hover:opacity-100 text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200 transition-opacity"
                  >
                    <.icon name="hero-pencil" class="h-3 w-3" />
                  </.link>
                </.link>
              </li>
            </ul>
            <div :if={@channels_count == 0} class="mt-4 px-2 text-xs text-zinc-500 italic">
              No channels yet.
            </div>
          </div>
          
    <!-- User Profile Area at Bottom of Context Sidebar -->
          <div class="mt-auto bg-zinc-100 dark:bg-[#232428] p-2 flex items-center justify-between shrink-0">
            <div class="flex items-center gap-2 min-w-0 hover:bg-zinc-200 dark:hover:bg-zinc-700/50 p-1 rounded-md transition-colors cursor-pointer flex-1">
              <div class="h-8 w-8 rounded-full bg-indigo-500 flex items-center justify-center text-white font-semibold text-sm shrink-0">
                {String.first(@current_scope.user.email) |> String.upcase()}
              </div>
              <div class="flex flex-col min-w-0">
                <span class="text-[13px] font-semibold truncate text-zinc-900 dark:text-zinc-100 leading-tight">
                  {@current_scope.user.email}
                </span>
                <span class="text-[11px] truncate text-zinc-500 dark:text-zinc-400 leading-tight">
                  Online
                </span>
              </div>
            </div>
            <div class="flex items-center gap-0.5 shrink-0 pl-1">
              <.link
                href={~p"/users/settings"}
                class="p-1.5 rounded flex items-center justify-center text-zinc-500 hover:bg-zinc-200 dark:hover:bg-zinc-700 hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors"
              >
                <.icon name="hero-cog-8-tooth" class="h-5 w-5" />
              </.link>
              <.link
                href={~p"/users/log-out"}
                method="delete"
                class="p-1.5 rounded flex items-center justify-center text-zinc-500 hover:bg-zinc-200 dark:hover:bg-zinc-700 hover:text-red-600 dark:hover:text-red-400 transition-colors"
              >
                <.icon name="hero-arrow-right-on-rectangle" class="h-5 w-5" />
              </.link>
            </div>
          </div>
        </div>
        
    <!-- Main Area (Server overview for this page) -->
        <div class="flex-1 flex flex-col bg-white dark:bg-[#313338] min-w-0">
          <header class="h-12 flex items-center px-4 shadow-sm border-b border-zinc-200 dark:border-zinc-800 shrink-0 gap-2">
            <.icon name="hero-information-circle" class="h-6 w-6 text-zinc-400 dark:text-zinc-500" />
            <h1 class="font-semibold text-md text-zinc-900 dark:text-zinc-100">
              Welcome to {@server.name}
            </h1>
          </header>

          <div class="flex-1 overflow-y-auto p-6 lg:p-10">
            <div class="max-w-4xl mx-auto grid gap-8 lg:grid-cols-3">
              <div class="lg:col-span-2 space-y-6">
                <div class="rounded-xl border border-zinc-200 bg-white p-6 shadow-sm dark:border-zinc-700/50 dark:bg-[#2B2D31]">
                  <div class="flex items-center justify-between mb-4">
                    <h2 class="text-sm font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
                      About Server
                    </h2>
                    <div class="flex items-center gap-2">
                      <.link
                        :if={@is_owner}
                        navigate={~p"/servers/#{@server}/edit?return_to=show"}
                        class="inline-flex items-center justify-center rounded-md px-3 py-1.5 text-xs font-semibold bg-zinc-100 text-zinc-900 hover:bg-zinc-200 dark:bg-zinc-700 dark:text-zinc-100 dark:hover:bg-zinc-600 transition-colors"
                      >
                        <.icon name="hero-pencil" class="mr-1.5 h-3.5 w-3.5" /> Edit
                      </.link>
                      <.button
                        :if={@is_owner}
                        phx-click="delete"
                        data-confirm="Are you sure you want to delete this server? This cannot be undone."
                        class="!py-1.5 !px-3 !text-xs bg-red-600 text-white hover:bg-red-700 transition-colors"
                      >
                        <.icon name="hero-trash" class="mr-1.5 h-3.5 w-3.5" /> Delete
                      </.button>
                    </div>
                  </div>
                  <p class="text-zinc-700 dark:text-zinc-300 leading-relaxed">
                    {if @server.description, do: @server.description, else: "No description provided."}
                  </p>
                  <div class="mt-6 pt-4 border-t border-zinc-100 dark:border-zinc-700/50 flex items-center gap-2 text-xs text-zinc-500">
                    <.icon name="hero-user" class="h-4 w-4" /> Created by
                    <span class="font-medium text-zinc-700 dark:text-zinc-300">
                      {@server.user.email}
                    </span>
                  </div>
                </div>
              </div>

              <div class="space-y-6">
                <div class="rounded-xl border border-zinc-200 bg-white shadow-sm dark:border-zinc-700/50 dark:bg-[#2B2D31]">
                  <div class="p-4 border-b border-zinc-100 dark:border-zinc-700/50 flex items-center justify-between">
                    <h2 class="text-sm font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
                      Members ({length(@server.server_members)})
                    </h2>
                    <%= if @is_member do %>
                      <.button
                        :if={!@is_owner}
                        phx-click="leave"
                        id="leave-btn"
                        class="!py-1 !px-2 !text-xs bg-zinc-100 text-zinc-700 hover:bg-zinc-200 dark:bg-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-600"
                      >
                        Leave
                      </.button>
                    <% else %>
                      <.button
                        phx-click="join"
                        id="join-btn"
                        class="!py-1 !px-3 !text-xs bg-indigo-600 text-white hover:bg-indigo-500"
                      >
                        Join
                      </.button>
                    <% end %>
                  </div>
                  <ul class="divide-y divide-zinc-100 dark:divide-zinc-700/50 max-h-96 overflow-y-auto hide-scrollbar p-2">
                    <li
                      :for={member <- @server.server_members}
                      class="flex items-center gap-3 p-2 rounded-md hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors"
                    >
                      <div class="relative flex h-8 w-8 items-center justify-center rounded-full bg-indigo-100 text-xs font-medium text-indigo-700 dark:bg-indigo-500 dark:text-white shrink-0">
                        {String.first(member.user.email) |> String.upcase()}
                        <div class="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full bg-emerald-500 border-2 border-white dark:border-[#2B2D31]">
                        </div>
                      </div>
                      <div class="flex-1 min-w-0">
                        <p class="truncate text-sm font-medium text-zinc-900 dark:text-zinc-100">
                          {member.user.email}
                        </p>
                      </div>
                      <span class={[
                        "inline-flex shrink-0 items-center rounded px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wider",
                        if(member.role == "owner",
                          do: "bg-amber-100 text-amber-700 dark:bg-amber-500/20 dark:text-amber-400",
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
