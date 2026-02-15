defmodule ChaoschatWeb.ChannelLive.Index do
  use ChaoschatWeb, :live_view

  alias Chaoschat.Servers

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Channels for {@server.name}
        <:actions>
          <.button variant="primary" navigate={~p"/servers/#{@server}/channels/new"}>
            <.icon name="hero-plus" /> New Channel
          </.button>
        </:actions>
      </.header>

      <.table
        id="channels"
        rows={@streams.channels}
        row_click={fn {_id, channel} -> JS.navigate(~p"/servers/#{@server}/channels/#{channel}") end}
      >
        <:col :let={{_id, channel}} label="Name">{channel.name}</:col>
        <:col :let={{_id, channel}} label="Description">{channel.description}</:col>
        <:action :let={{_id, channel}}>
          <div class="sr-only">
            <.link navigate={~p"/servers/#{@server}/channels/#{channel}"}>Show</.link>
          </div>
          <.link navigate={~p"/servers/#{@server}/channels/#{channel}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, channel}}>
          <.link
            phx-click={JS.push("delete", value: %{id: channel.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"server_id" => server_id}, _session, socket) do
    if connected?(socket) do
      Servers.subscribe_channels(socket.assigns.current_scope)
    end

    server = Servers.get_server!(socket.assigns.current_scope, server_id)

    {:ok,
     socket
     |> assign(:page_title, "Listing Channels")
     |> assign(:server, server)
     |> stream(:channels, list_channels(socket.assigns.current_scope, server.id))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    channel = Servers.get_channel!(socket.assigns.current_scope, id)
    {:ok, _} = Servers.delete_channel(socket.assigns.current_scope, channel)

    {:noreply, stream_delete(socket, :channels, channel)}
  end

  @impl true
  def handle_info({type, %Chaoschat.Servers.Channel{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply,
     stream(
       socket,
       :channels,
       list_channels(socket.assigns.current_scope, socket.assigns.server.id),
       reset: true
     )}
  end

  defp list_channels(current_scope, server_id) do
    Servers.list_channels(current_scope, server_id)
  end
end
