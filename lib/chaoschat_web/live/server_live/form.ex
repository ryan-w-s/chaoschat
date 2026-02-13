defmodule ChaoschatWeb.ServerLive.Form do
  use ChaoschatWeb, :live_view

  alias Chaoschat.Servers
  alias Chaoschat.Servers.Server

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage server records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="server-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Server</.button>
          <.button navigate={return_path(@current_scope, @return_to, @server)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    server = Servers.get_server!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Server")
    |> assign(:server, server)
    |> assign(:form, to_form(Servers.change_server(socket.assigns.current_scope, server)))
  end

  defp apply_action(socket, :new, _params) do
    server = %Server{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Server")
    |> assign(:server, server)
    |> assign(:form, to_form(Servers.change_server(socket.assigns.current_scope, server)))
  end

  @impl true
  def handle_event("validate", %{"server" => server_params}, socket) do
    changeset =
      Servers.change_server(socket.assigns.current_scope, socket.assigns.server, server_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"server" => server_params}, socket) do
    save_server(socket, socket.assigns.live_action, server_params)
  end

  defp save_server(socket, :edit, server_params) do
    case Servers.update_server(socket.assigns.current_scope, socket.assigns.server, server_params) do
      {:ok, server} ->
        {:noreply,
         socket
         |> put_flash(:info, "Server updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, server)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_server(socket, :new, server_params) do
    case Servers.create_server(socket.assigns.current_scope, server_params) do
      {:ok, server} ->
        {:noreply,
         socket
         |> put_flash(:info, "Server created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, server)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _server), do: ~p"/servers"
  defp return_path(_scope, "show", server), do: ~p"/servers/#{server}"
end
