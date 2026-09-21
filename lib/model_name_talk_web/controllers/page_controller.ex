defmodule ModelNameTalkWeb.PageController do
  use ModelNameTalkWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
