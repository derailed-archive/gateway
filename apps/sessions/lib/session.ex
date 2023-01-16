defmodule Derailed.Session do
  use GenServer
  require Logger

  @spec start_link(pid(), pid()) :: {:ok, pid}
  def start_link(session_id, ws_pid) do
    Logger.debug("Spinning up new Session: #{inspect(session_id)}/#{inspect(ws_pid)}")
    GenServer.start_link(__MODULE__, {session_id, ws_pid})
  end

  def init({session_id, ws_pid}) do
    {:ok,
     %{
       id: session_id,
       guild_pids: Map.new(),
       ws_pid: ws_pid
     }}
  end
end
