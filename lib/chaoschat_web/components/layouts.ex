defmodule ChaoschatWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use ChaoschatWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :joined_servers, :list,
    default: nil,
    doc: "the list of servers the current user has joined"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="flex h-screen w-full overflow-hidden bg-white text-zinc-900 dark:bg-[#313338] dark:text-zinc-100">
      <!-- Leftmost sidebar (Server List) -->
      <%= if @joined_servers do %>
        <nav class="w-[72px] flex-shrink-0 bg-zinc-100 dark:bg-[#1E1F22] flex flex-col items-center py-3 gap-2 overflow-y-auto hide-scrollbar border-r border-zinc-200 dark:border-zinc-800/50">
          <.link
            navigate={~p"/servers"}
            class="flex h-12 w-12 items-center justify-center rounded-[24px] bg-white text-zinc-900 hover:rounded-[16px] hover:bg-indigo-600 hover:text-white transition-all duration-200 shadow-sm dark:bg-[#313338] dark:text-zinc-100 dark:hover:bg-indigo-500"
          >
            <.icon name="hero-home" class="h-6 w-6" />
          </.link>
          <div class="w-8 h-[2px] bg-zinc-200 dark:bg-zinc-700/50 rounded-full my-1"></div>

          <div :for={server <- @joined_servers} class="relative group flex justify-center w-full">
            <div class="absolute left-0 w-1 h-2 bg-zinc-800 dark:bg-zinc-200 rounded-r-md top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 group-hover:h-5 transition-all duration-200">
            </div>
            <.link
              navigate={~p"/servers/#{server}"}
              class="flex h-12 w-12 items-center justify-center rounded-[24px] bg-white text-zinc-900 hover:rounded-[16px] hover:bg-indigo-600 hover:text-white transition-all duration-200 shadow-sm dark:bg-[#313338] dark:text-zinc-100 dark:hover:bg-indigo-500 overflow-hidden font-medium text-lg"
            >
              {String.first(server.name) |> String.upcase()}
            </.link>
          </div>

          <.link
            navigate={~p"/servers/new"}
            class="flex h-12 w-12 items-center justify-center rounded-[24px] bg-white text-emerald-600 hover:rounded-[16px] hover:bg-emerald-600 hover:text-white transition-all duration-200 shadow-sm dark:bg-[#313338] dark:hover:bg-emerald-500 mt-2"
          >
            <.icon name="hero-plus" class="h-6 w-6" />
          </.link>

          <div class="flex-1"></div>

          <div class="flex flex-col items-center gap-4 mt-4 w-full px-2">
            <.theme_toggle />
          </div>
        </nav>
      <% end %>
      
    <!-- Main Content Area -->
      <main class="flex-1 flex flex-col min-w-0 bg-white dark:bg-[#313338] h-full overflow-hidden relative">
        <.flash_group flash={@flash} />

        <%= if !@joined_servers do %>
          <header class="navbar px-4 py-3 flex items-center justify-between border-b border-zinc-200 dark:border-zinc-700/50 absolute top-0 w-full z-10 bg-white/80 dark:bg-[#313338]/80 backdrop-blur-sm">
            <div class="flex-1 flex items-center gap-2">
              <img src={~p"/images/logo.svg"} width="36" />
              <span class="text-sm font-semibold">Chaoschat</span>
            </div>
            <ul class="flex items-center gap-6 text-sm font-medium">
              <%= if @current_scope do %>
                <li class="text-zinc-500 dark:text-zinc-400">{@current_scope.user.email}</li>
                <li>
                  <.link
                    navigate={~p"/users/settings"}
                    class="hover:text-indigo-600 dark:hover:text-indigo-400"
                  >
                    Settings
                  </.link>
                </li>
                <li>
                  <.link
                    href={~p"/users/log-out"}
                    method="delete"
                    class="hover:text-indigo-600 dark:hover:text-indigo-400"
                  >
                    Log out
                  </.link>
                </li>
              <% else %>
                <li>
                  <.link
                    navigate={~p"/users/register"}
                    class="hover:text-indigo-600 dark:hover:text-indigo-400"
                  >
                    Register
                  </.link>
                </li>
                <li>
                  <.link
                    navigate={~p"/users/log-in"}
                    class="hover:text-indigo-600 dark:hover:text-indigo-400"
                  >
                    Log in
                  </.link>
                </li>
              <% end %>
              <li><.theme_toggle /></li>
            </ul>
          </header>
          <div class="flex-1 overflow-y-auto w-full h-full pt-16">
            <div class="mx-auto max-w-2xl px-4 sm:px-6 lg:px-8 py-8 w-full">
              {render_slot(@inner_block)}
            </div>
          </div>
        <% else %>
          <div class="flex-1 h-full flex flex-col min-w-0 overflow-hidden">
            {render_slot(@inner_block)}
          </div>
        <% end %>
      </main>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
