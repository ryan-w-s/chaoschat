defmodule ChaoschatWeb.ChannelLiveTest do
  use ChaoschatWeb.ConnCase

  import Phoenix.LiveViewTest
  import Chaoschat.ServersFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  setup :register_and_log_in_user

  defp create_channel(%{scope: scope}) do
    channel = channel_fixture(scope)
    server = Chaoschat.Servers.get_server!(scope, channel.server_id)
    %{channel: channel, server: server}
  end

  describe "Index" do
    setup [:create_channel]

    test "lists all channels", %{conn: conn, channel: channel, server: server} do
      {:ok, _index_live, html} = live(conn, ~p"/servers/#{server}/channels")

      assert html =~ "Listing Channels"
      assert html =~ channel.name
    end

    test "saves new channel", %{conn: conn, server: server} do
      {:ok, index_live, _html} = live(conn, ~p"/servers/#{server}/channels")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Channel")
               |> render_click()
               |> follow_redirect(conn, ~p"/servers/#{server}/channels/new")

      assert render(form_live) =~ "New Channel"

      assert form_live
             |> form("#channel-form", channel: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#channel-form", channel: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/servers/#{server}")

      html = render(index_live)
      assert html =~ "Channel created successfully"
      assert html =~ "some name"
    end

    test "updates channel in listing", %{conn: conn, channel: channel, server: server} do
      {:ok, index_live, _html} = live(conn, ~p"/servers/#{server}/channels")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#channels-#{channel.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/servers/#{server}/channels/#{channel}/edit")

      assert render(form_live) =~ "Edit Channel"

      assert form_live
             |> form("#channel-form", channel: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#channel-form", channel: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/servers/#{server}")

      html = render(index_live)
      assert html =~ "Channel updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes channel in listing", %{conn: conn, channel: channel, server: server} do
      {:ok, index_live, _html} = live(conn, ~p"/servers/#{server}/channels")

      assert index_live |> element("#channels-#{channel.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#channels-#{channel.id}")
    end
  end

  describe "Show" do
    setup [:create_channel]

    test "displays channel", %{conn: conn, channel: channel, server: server} do
      {:ok, _show_live, html} = live(conn, ~p"/servers/#{server}/channels/#{channel}")

      assert html =~ "Show Channel"
      assert html =~ channel.name
    end

    test "updates channel and returns to show", %{conn: conn, channel: channel, server: server} do
      {:ok, show_live, _html} = live(conn, ~p"/servers/#{server}/channels/#{channel}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a[title='Edit Channel']")
               |> render_click()
               |> follow_redirect(
                 conn,
                 ~p"/servers/#{server}/channels/#{channel}/edit?return_to=show"
               )

      assert render(form_live) =~ "Edit Channel"

      assert form_live
             |> form("#channel-form", channel: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#channel-form", channel: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/servers/#{server}/channels/#{channel}")

      html = render(show_live)
      assert html =~ "Channel updated successfully"
      assert html =~ "some updated name"
    end
  end
end
