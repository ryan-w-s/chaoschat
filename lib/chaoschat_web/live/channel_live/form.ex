defmodule ChaoschatWeb.ChannelLive.Form do
  use ChaoschatWeb, :live_view

  alias Chaoschat.Servers
  alias Chaoschat.Servers.Channel

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage channel records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="channel-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Channel</.button>
          <.button navigate={return_path(@current_scope, @return_to, @channel)}>Cancel</.button>
        </footer>
      </.form>
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

  defp return_path(_scope, "index", channel), do: ~p"/servers/#{channel.server_id}/channels"

  defp return_path(_scope, "show", channel),
    do: ~p"/servers/#{channel.server_id}/channels/#{channel}"
end
