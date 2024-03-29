defmodule Derailed.Session do
  use GenServer
  require Logger

  @spec start_link(String.t, pid()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(user_id, ws_pid) do
    Logger.debug "Spinning up new Session"
    GenServer.start_link(__MODULE__, {user_id, ws_pid})
  end

  def init({user_id, ws_pid}) do
    {:ok, %{
      id: user_id,
      ws_pid: ws_pid
    }}
  end

  @spec get_id(pid()) :: String.t
  def get_id(pid) do
    GenServer.call(pid, :get_id)
  end

  def handle_call(:get_id, _from, state) do
    state.id
  end

  def handle_info(msg, state) do
    Logger.debug "Handing off message to #{state.id}: #{inspect msg}"
    Manifold.send(state.ws_pid, Map.new(msg))
    {:noreply, state}
  end
end
