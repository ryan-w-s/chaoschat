defmodule ChaoschatWeb.ServerLive.Index do
  use ChaoschatWeb, :live_view

  alias Chaoschat.Servers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Servers
        <:actions>
          <.button variant="primary" navigate={~p"/servers/new"}>
            <.icon name="hero-plus" /> New Server
          </.button>
        </:actions>
      </.header>

      <div id="servers" phx-update="stream" class="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <div id="servers-empty" class="hidden only:block text-center py-12 text-zinc-500">
          No servers yet. Create the first one!
        </div>
        <div
          :for={{id, server} <- @streams.servers}
          id={id}
          class="group relative rounded-xl border border-zinc-200 bg-white p-6 shadow-sm transition hover:shadow-md hover:border-zinc-300 dark:border-zinc-700 dark:bg-zinc-800 dark:hover:border-zinc-600"
        >
          <.link navigate={~p"/servers/#{server}"} class="absolute inset-0 z-10">
            <span class="sr-only">View {server.name}</span>
          </.link>
          <div class="flex items-center justify-between">
            <h3 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100 group-hover:text-indigo-600 dark:group-hover:text-indigo-400 transition-colors">
              {server.name}
            </h3>
            <span
              :if={server.user_id == @current_scope.user.id}
              class="inline-flex items-center rounded-full bg-indigo-50 px-2 py-0.5 text-xs font-medium text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-400"
            >
              Owner
            </span>
          </div>
          <p
            :if={server.description}
            class="mt-2 text-sm text-zinc-600 dark:text-zinc-400 line-clamp-2"
          >
            {server.description}
          </p>
          <div class="mt-4 flex items-center gap-4 text-xs text-zinc-500 dark:text-zinc-500">
            <span class="flex items-center gap-1">
              <.icon name="hero-user-group" class="h-3.5 w-3.5" />
              {Map.get(@member_counts, server.id, 0)} members
            </span>
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
