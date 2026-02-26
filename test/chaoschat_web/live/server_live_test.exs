defmodule ChaoschatWeb.ServerLiveTest do
  use ChaoschatWeb.ConnCase

  import Phoenix.LiveViewTest
  import Chaoschat.ServersFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  setup :register_and_log_in_user

  defp create_server(%{scope: scope}) do
    server = server_fixture(scope)

    %{server: server}
  end

  describe "Index" do
    setup [:create_server]

    test "lists all servers", %{conn: conn, server: server} do
      {:ok, _index_live, html} = live(conn, ~p"/servers")

      assert html =~ "Servers"
      assert html =~ server.name
    end

    test "saves new server", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/servers")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Server")
               |> render_click()
               |> follow_redirect(conn, ~p"/servers/new")

      assert render(form_live) =~ "New Server"

      assert form_live
             |> form("#server-form", server: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:error, {:live_redirect, %{to: path}}} =
               form_live
               |> form("#server-form", server: @create_attrs)
               |> render_submit()

      assert {:ok, index_live, _html} = live(conn, path)

      html = render(index_live)
      assert html =~ "some name"
    end
  end

  describe "Show" do
    setup [:create_server]

    test "displays server", %{conn: conn, server: server} do
      {:ok, _show_live, html} = live(conn, ~p"/servers/#{server}")

      assert html =~ server.name
    end

    test "owner can edit server", %{conn: conn, server: server} do
      {:ok, show_live, _html} = live(conn, ~p"/servers/#{server}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/servers/#{server}/edit?return_to=show")

      assert render(form_live) =~ "Edit Server"

      assert form_live
             |> form("#server-form", server: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#server-form", server: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/servers/#{server}")

      html = render(show_live)
      assert html =~ "Server updated successfully"
      assert html =~ "some updated name"
    end

    test "owner can delete server", %{conn: conn, server: server} do
      {:ok, show_live, _html} = live(conn, ~p"/servers/#{server}")

      assert has_element?(show_live, "button", "Delete")

      render_click(show_live, "delete")

      assert_redirect(show_live, ~p"/servers")
    end
  end
end
