defmodule HelloWeb.PageController do
  use HelloWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
    indicator_r = 0
    indicator_w = 0
    sequenceNum = 0
    request_hitcount = 0
    state = {:running, indicator_r, indicator_w, sequenceNum, request_hitcount}
    {:ok, pid} = GenServer.start(Server, state, name: :server)
    GenServer.call(:server, :start, :infinity)
  end

  def paajiRohit(conn, _params) do
    render conn, "error.html"
  end 
end
