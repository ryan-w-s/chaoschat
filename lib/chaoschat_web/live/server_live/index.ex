defmodule ChaoschatWeb.ServerLive.Index do
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
      <div class="flex h-full w-full bg-zinc-50 dark:bg-[#313338]">
        <!-- Home Sidebar -->
        <div class="w-60 flex-shrink-0 bg-zinc-100 dark:bg-[#2B2D31] flex flex-col overflow-hidden">
          <div class="p-3">
            <button class="w-full text-left px-3 py-2 rounded-md bg-zinc-200 dark:bg-[#3F4147] text-zinc-900 dark:text-zinc-100 font-medium flex items-center gap-3 transition-colors">
              <.icon name="hero-users" class="h-5 w-5 opacity-70" /> Friends
            </button>
          </div>

          <div class="p-3 flex-1 overflow-y-auto hide-scrollbar">
            <h2 class="text-[11px] font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400 mb-2 px-1">
              Direct Messages (WIP)
            </h2>
          </div>
          
    <!-- User Profile Area at Bottom -->
          <div class="mt-auto bg-zinc-200 dark:bg-[#232428] p-2 flex items-center justify-between shrink-0">
            <div class="flex items-center gap-2 min-w-0 hover:bg-zinc-300 dark:hover:bg-zinc-700/50 p-1 rounded-md transition-colors cursor-pointer flex-1">
              <div class="h-8 w-8 rounded-full bg-indigo-500 flex items-center justify-center text-white font-semibold text-sm shrink-0">
                {String.first(@current_scope.user.email) |> String.upcase()}
              </div>
              <div class="flex flex-col min-w-0">
                <span class="text-[13px] font-semibold truncate text-zinc-900 dark:text-zinc-100 leading-tight">
                  {@current_scope.user.email}
                </span>
              </div>
            </div>
            <div class="flex items-center gap-0.5 shrink-0 pl-1">
              <.link
                href={~p"/users/settings"}
                class="p-1.5 rounded flex items-center justify-center text-zinc-500 hover:bg-zinc-300 dark:hover:bg-zinc-700 hover:text-zinc-900 dark:hover:text-zinc-100 transition-colors"
              >
                <.icon name="hero-cog-8-tooth" class="h-5 w-5" />
              </.link>
              <.link
                href={~p"/users/log-out"}
                method="delete"
                class="p-1.5 rounded flex items-center justify-center text-zinc-500 hover:bg-zinc-300 dark:hover:bg-zinc-700 hover:text-red-600 dark:hover:text-red-400 transition-colors"
              >
                <.icon name="hero-arrow-right-on-rectangle" class="h-5 w-5" />
              </.link>
            </div>
          </div>
        </div>
        
    <!-- Main Discover Area -->
        <div class="flex-1 flex flex-col min-w-0 p-6 lg:p-10 overflow-y-auto">
          <header class="flex items-center justify-between mb-8">
            <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100 flex items-center gap-2">
              <.icon name="hero-globe-alt" class="h-8 w-8 text-indigo-500" /> Discover Servers
            </h1>
            <.button variant="primary" navigate={~p"/servers/new"}>
              <.icon name="hero-plus" /> New Server
            </.button>
          </header>

          <div
            id="servers"
            phx-update="stream"
            class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4"
          >
            <div
              id="servers-empty"
              class="hidden only:block col-span-full text-center py-16 text-zinc-500 border-2 border-dashed border-zinc-200 dark:border-zinc-700/50 rounded-xl"
            >
              No servers yet. Create the first one!
            </div>
            <div
              :for={{id, server} <- @streams.servers}
              id={id}
              class="group relative rounded-xl border border-zinc-200 bg-white p-5 shadow-sm transition-all duration-200 hover:shadow-md hover:border-indigo-300 hover:-translate-y-1 dark:border-zinc-700/50 dark:bg-[#2B2D31] dark:hover:border-indigo-500/50"
            >
              <.link navigate={~p"/servers/#{server}"} class="absolute inset-0 z-10">
                <span class="sr-only">View {server.name}</span>
              </.link>

              <div class="flex items-start justify-between mb-4">
                <div class="h-12 w-12 rounded-[16px] bg-indigo-100 dark:bg-indigo-500/20 text-indigo-700 dark:text-indigo-400 flex items-center justify-center font-bold text-xl group-hover:bg-indigo-600 group-hover:text-white transition-colors shadow-sm">
                  {String.first(server.name) |> String.upcase()}
                </div>
                <span
                  :if={server.user_id == @current_scope.user.id}
                  class="inline-flex items-center rounded bg-amber-100 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-amber-700 dark:bg-amber-500/20 dark:text-amber-400"
                >
                  Owner
                </span>
              </div>

              <h3 class="text-lg font-bold text-zinc-900 dark:text-zinc-100 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors truncate">
                {server.name}
              </h3>

              <p
                :if={server.description}
                class="mt-1.5 text-sm text-zinc-600 dark:text-zinc-400 line-clamp-2 leading-relaxed"
              >
                {server.description}
              </p>
              <div class="mt-4 flex items-center gap-4 text-xs font-medium text-zinc-500 dark:text-zinc-400">
                <span class="flex items-center gap-1.5 bg-zinc-100 dark:bg-zinc-800/50 px-2 py-1 rounded-md">
                  <div class="w-2 h-2 rounded-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.8)]">
                  </div>
                  {Map.get(@member_counts, server.id, 0)} members
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Servers.subscribe_servers(socket.assigns.current_scope)
    end

    servers = Servers.list_all_servers()
    member_counts = Map.new(servers, fn s -> {s.id, Servers.member_count(s)} end)

    {:ok,
     socket
     |> assign(:page_title, "Servers")
     |> assign(:member_counts, member_counts)
     |> stream(:servers, servers)}
  end

  @impl true
  def handle_info({type, %Chaoschat.Servers.Server{}}, socket)
      when type in [:created, :updated, :deleted] do
    servers = Servers.list_all_servers()
    member_counts = Map.new(servers, fn s -> {s.id, Servers.member_count(s)} end)

    {:noreply,
     socket
     |> assign(:member_counts, member_counts)
     |> stream(:servers, servers, reset: true)}
  end
end
