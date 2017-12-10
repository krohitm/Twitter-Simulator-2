defmodule HelloWeb.PageController do
  use HelloWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def paajiRohit(conn, _params) do
    render conn, "error.html"
  end
end
