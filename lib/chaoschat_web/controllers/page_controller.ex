defmodule ChaoschatWeb.PageController do
  use ChaoschatWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
