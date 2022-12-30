defmodule Derailed.Guild do
  use GenServer
  require Logger

  # client
  def start_link(guild_id) do
    Logger.debug "Spinning up new Guild"
    GenServer.start_link(__MODULE__, guild_id)
  end

  @spec subscribe(pid(), pid()) :: :ok
  def subscribe(pid, session_pid) do
    GenServer.cast(pid, {:subscribe, session_pid})
  end

  @spec unsubscribe(pid(), pid()) :: :ok
  def unsubscribe(pid, session_pid) do
    GenServer.cast(pid, {:unsubscribe, session_pid})
  end

  @spec publish(pid(), Map) :: :ok
  def publish(pid, message) do
    GenServer.cast(pid, {:publish, message})
  end

  @spec exists(pid(), pid()) :: boolean
  def exists(pid, session_pid) do
    GenServer.call(pid, {:exists, pid, session_pid})
  end

  @spec get_presence_count(pid()) :: integer
  def get_presence_count(pid) do
    GenServer.call(pid, :get_presence_count)
  end

  # server
  def init(guild_id) do
    {:ok, %{
      id: guild_id,
      sessions: MapSet.new()
    }}
  end

  def handle_call({:exists, pid, session_pid}, _from, state) do
    Logger.debug "Checking if session id #{inspect pid} exists"
    {:reply, MapSet.member?(state.sessions, session_pid), state}
  end

  def handle_call(:get_presence_count, _from, state) do
    Logger.debug "Getting Presence count for Guild #{state.id}"
    presence_count = Enum.count_until(state.sessions, 1000)
    {:reply, presence_count, state}
  end

  def handle_cast({:subscribe, session_pid}, state) do
    Logger.debug("Subscribing #{inspect session_pid} to #{state.id}")
    {:noreply, %{state | sessions: MapSet.put(state.sessions, session_pid)}}
  end

  def handle_cast({:unsubscribe, session_pid}, state) do
    Logger.debug("Unsubscribing #{inspect session_pid} from #{state.id}")
    new_map = MapSet.delete(state.sessions, session_pid)

    # TODO: Stop GenServer when MapSet.equal?(new_map, MapSet.new())

    {:noreply, %{state | sessions: new_map}}
  end

  def handle_cast({:publish, message}, state) do
    Logger.debug "Publishing message to #{state.id}: #{inspect message}"
    Enum.each(state.sessions, &Manifold.send(&1, message))
    {:noreply, state}
  end
end
