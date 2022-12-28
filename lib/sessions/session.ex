defmodule Derailed.Session do
  use GenServer
  require Logger

  def start_link(ws_pid) do
    Logger.debug "Spinning up new Session"
    GenServer.start_link(__MODULE__, ws_pid)
  end

  def init(ws_pid) do
    {:ok, %{
      ws_pid: ws_pid
    }}
  end

  def handle_info({:event, data}, state) do
    Manifold.send(state.ws_pid, data)
    {:noreply, state}
  end
end
