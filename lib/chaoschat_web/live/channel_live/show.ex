defmodule ChaoschatWeb.ChannelLive.Show do
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
          <.link
            navigate={~p"/servers/#{@server}"}
            class="h-12 flex items-center justify-between px-4 font-semibold shadow-sm text-zinc-900 dark:text-zinc-100 border-b border-zinc-200 dark:border-zinc-800 shrink-0 transition hover:bg-zinc-200/50 dark:hover:bg-zinc-700/50 cursor-pointer"
          >
            <span class="truncate">{@server.name}</span>
            <.icon name="hero-chevron-down" class="h-4 w-4 text-zinc-500" />
          </.link>

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
                  class={[
                    "flex items-center gap-2 px-2 py-1.5 rounded-md transition-colors font-medium group",
                    if(@channel.id == channel.id,
                      do: "bg-zinc-200 text-zinc-900 dark:bg-[#3F4147] dark:text-zinc-100",
                      else:
                        "text-zinc-600 hover:bg-zinc-200 hover:text-zinc-900 dark:text-zinc-400 dark:hover:bg-[#3F4147] dark:hover:text-zinc-100"
                    )
                  ]}
                >
                  <.icon
                    name="hero-hashtag"
                    class={[
                      "h-5 w-5",
                      if(@channel.id == channel.id,
                        do: "opacity-100",
                        else: "opacity-50 group-hover:opacity-100"
                      )
                    ]}
                  />
                  <span class="truncate flex-1">{channel.name}</span>
                  <.link
                    :if={@is_owner}
                    navigate={~p"/servers/#{@server}/channels/#{channel}/edit"}
                    class={[
                      "transition-opacity text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200",
                      if(@channel.id == channel.id,
                        do: "opacity-100",
                        else: "opacity-0 group-hover:opacity-100"
                      )
                    ]}
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
        
    <!-- Main Area (Channel Content) -->
        <div class="flex-1 flex flex-col bg-white dark:bg-[#313338] min-w-0">
          <header class="h-12 flex items-center justify-between px-4 shadow-sm border-b border-zinc-200 dark:border-zinc-800 shrink-0">
            <div class="flex items-center gap-2">
              <.icon name="hero-hashtag" class="h-6 w-6 text-zinc-400 dark:text-zinc-500" />
              <h1 class="font-semibold text-md text-zinc-900 dark:text-zinc-100">{@channel.name}</h1>
              <span
                :if={@channel.description}
                class="hidden sm:block ml-2 px-2 border-l border-zinc-300 dark:border-zinc-700 text-sm text-zinc-500 truncate mt-0.5"
              >
                {@channel.description}
              </span>
            </div>
            <div class="flex items-center gap-2">
              <.link
                :if={@is_owner}
                navigate={~p"/servers/#{@server}/channels/#{@channel}/edit?return_to=show"}
                class="text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-200 p-2"
                title="Edit Channel"
              >
                <.icon name="hero-pencil" class="h-5 w-5" />
              </.link>
            </div>
          </header>

          <div class="flex-1 overflow-y-auto p-4 flex flex-col justify-end">
            <div class="mb-4">
              <div class="h-16 w-16 bg-zinc-200 dark:bg-zinc-700 rounded-full flex items-center justify-center mb-4">
                <.icon name="hero-hashtag" class="h-10 w-10 text-zinc-500 dark:text-zinc-400" />
              </div>
              <h2 class="text-3xl font-bold text-zinc-900 dark:text-zinc-100 mb-2">
                Welcome to #{@channel.name}!
              </h2>
              <p class="text-zinc-600 dark:text-zinc-400 font-medium text-lg">
                This is the start of the
                <span class="text-indigo-600 dark:text-indigo-400">#{@channel.name}</span>
                channel.
              </p>
              <p :if={@channel.description} class="text-zinc-500 dark:text-zinc-500 mt-1">
                {@channel.description}
              </p>
            </div>

            <div class="flex-1 min-h-[50px]">
              <!-- Messages will go here -->
            </div>
          </div>
          
    <!-- Chat Input Area (stub) -->
          <div class="p-4 pt-0 shrink-0">
            <div class="bg-zinc-100 dark:bg-[#383A40] rounded-lg flex items-center px-4 py-2 opacity-50 cursor-not-allowed">
              <.icon name="hero-plus-circle" class="h-6 w-6 text-zinc-400" />
              <div class="flex-1 bg-transparent px-3 py-1.5 focus:outline-none text-zinc-500">
                Message #{@channel.name}... (Coming Soon)
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"server_id" => server_id, "id" => id}, _session, socket) do
    if connected?(socket) do
      Servers.subscribe_channels(socket.assigns.current_scope)
    end

    scope = socket.assigns.current_scope
    server = Servers.get_server!(scope, server_id)
    channels = Servers.list_channels(scope, server.id)
    is_owner = server.user_id == scope.user.id

    {:ok,
     socket
     |> assign(:page_title, "Show Channel")
     |> assign(:server, server)
     |> assign(:is_owner, is_owner)
     |> assign(:channels_count, length(channels))
     |> assign(:channel, Servers.get_channel!(scope, id))
     |> stream(:channels, channels)}
  end

  @impl true
  def handle_info(
        {:updated, %Chaoschat.Servers.Channel{id: id} = channel},
        %{assigns: %{channel: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :channel, channel)}
  end

  def handle_info(
        {:deleted, %Chaoschat.Servers.Channel{id: id}},
        %{assigns: %{channel: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current channel was deleted.")
     |> push_navigate(to: ~p"/servers/#{socket.assigns.server}/channels")}
  end

  def handle_info({type, %Chaoschat.Servers.Channel{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
