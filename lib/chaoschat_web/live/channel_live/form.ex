defmodule ChaoschatWeb.ChannelLive.Form do
  use ChaoschatWeb, :live_view

  alias Chaoschat.Servers
  alias Chaoschat.Servers.Channel

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} joined_servers={@joined_servers}>
      <div class="flex items-center justify-center h-full w-full p-4 sm:p-6 lg:p-8 bg-zinc-50 dark:bg-[#313338]">
        <div class="w-full max-w-md bg-white dark:bg-[#2B2D31] rounded-2xl shadow-xl overflow-hidden border border-zinc-200 dark:border-zinc-700/50">
          <div class="px-6 py-8">
            <h1 class="text-2xl font-bold text-center text-zinc-900 dark:text-white mb-2">
              {@page_title}
            </h1>
            <p class="text-sm text-center text-zinc-500 dark:text-zinc-400 mb-8">
              Manage your channel.
            </p>

            <.form
              for={@form}
              id="channel-form"
              phx-change="validate"
              phx-submit="save"
              class="space-y-4"
            >
              <.input field={@form[:name]} type="text" label="Channel Name" required />
              <.input field={@form[:description]} type="text" label="Description" />

              <div class="pt-6 flex items-center justify-between gap-3 mt-8">
                <.link
                  navigate={return_path(@current_scope, @return_to, @channel)}
                  class="text-sm font-semibold text-zinc-600 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-white hover:underline transition-all"
                >
                  Cancel
                </.link>
                <.button
                  phx-disable-with="Saving..."
                  class="!py-2 !px-6 bg-indigo-600 hover:bg-indigo-500 text-white font-medium rounded-md transition-colors border-none shadow-md"
                >
                  Save Channel
                </.button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true

  def mount(params, _session, socket) do
    server = Servers.get_server!(socket.assigns.current_scope, params["server_id"])

    {:ok,
     socket
     |> assign(:server, server)
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    channel = Servers.get_channel!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Channel")
    |> assign(:channel, channel)
    |> assign(:form, to_form(Servers.change_channel(socket.assigns.current_scope, channel)))
  end

  defp apply_action(socket, :new, _params) do
    channel = %Channel{
      user_id: socket.assigns.current_scope.user.id,
      server_id: socket.assigns.server.id
    }

    socket
    |> assign(:page_title, "New Channel")
    |> assign(:channel, channel)
    |> assign(:form, to_form(Servers.change_channel(socket.assigns.current_scope, channel)))
  end

  @impl true
  def handle_event("validate", %{"channel" => channel_params}, socket) do
    changeset =
      Servers.change_channel(socket.assigns.current_scope, socket.assigns.channel, channel_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"channel" => channel_params}, socket) do
    # Inject server_id for new channels if not present (although we set it in struct, form params override)
    channel_params = Map.put_new(channel_params, "server_id", socket.assigns.server.id)
    save_channel(socket, socket.assigns.live_action, channel_params)
  end

  defp save_channel(socket, :edit, channel_params) do
    case Servers.update_channel(
           socket.assigns.current_scope,
           socket.assigns.channel,
           channel_params
         ) do
      {:ok, channel} ->
        {:noreply,
         socket
         |> put_flash(:info, "Channel updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, channel)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_channel(socket, :new, channel_params) do
    case Servers.create_channel(socket.assigns.current_scope, channel_params) do
      {:ok, channel} ->
        {:noreply,
         socket
         |> put_flash(:info, "Channel created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, channel)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", channel), do: ~p"/servers/#{channel.server_id}"

  defp return_path(_scope, "show", channel),
    do: ~p"/servers/#{channel.server_id}/channels/#{channel}"
end
