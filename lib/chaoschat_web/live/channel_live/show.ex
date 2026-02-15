defmodule ChaoschatWeb.ChannelLive.Show do
  use ChaoschatWeb, :live_view

  alias Chaoschat.Servers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Channel {@channel.id}
        <:subtitle>This is a channel record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/servers/#{@server}/channels"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button
            variant="primary"
            navigate={~p"/servers/#{@server}/channels/#{@channel}/edit?return_to=show"}
          >
            <.icon name="hero-pencil-square" /> Edit channel
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@channel.name}</:item>
        <:item title="Description">{@channel.description}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"server_id" => server_id, "id" => id}, _session, socket) do
    if connected?(socket) do
      Servers.subscribe_channels(socket.assigns.current_scope)
    end

    server = Servers.get_server!(socket.assigns.current_scope, server_id)

    {:ok,
     socket
     |> assign(:page_title, "Show Channel")
     |> assign(:server, server)
     |> assign(:channel, Servers.get_channel!(socket.assigns.current_scope, id))}
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
