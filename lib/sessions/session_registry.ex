defmodule Derailed.Session.Registry do
  use GenServer
  require Logger

  def start_link(user_id) do
    Logger.debug "Spinning up new Session Registry for User #{user_id}"
    GenServer.start_link(__MODULE__, user_id)
  end

  def init(user_id) do
    {:ok, %{
      id: user_id,
      sessions: MapSet.new()
    }}
  end

  @spec add_session(pid(), pid()) :: :ok
  def add_session(pid, session_pid) do
    GenServer.cast(pid, {:add_session, session_pid})
  end

  @spec remove_session(pid(), pid()) :: :ok
  def remove_session(pid, session_pid) do
    GenServer.cast(pid, {:remove_session, session_pid})
  end

  @spec get_sessions(pid()) :: list
  def get_sessions(pid) do
    GenServer.call(pid, :get_sessions)
  end

  @spec offlineable(pid(), pid()) :: boolean
  def offlineable(pid, session_pid) do
    GenServer.call(pid, {:offlineable, session_pid})
  end

  def handle_call(:get_sessions, _from, state) do
    {:reply, state.sessions, state}
  end

  def handle_call({:offlineable, session_pid}, _from, state) do
    {:reply, Enum.empty?(MapSet.delete(state.sessions, session_pid)), state}
  end

  def handle_cast({:add_session, pid}, state) do
    {:noreply, %{state | sessions: MapSet.put(state.sessions, pid)}}
  end

  def handle_cast({:remove_session, pid}, state) do
    new_map = MapSet.put(state.sessions, pid)

    if new_map == MapSet.new() do
      {:stop, :no_more_sessions, state}
    end

    {:noreply, %{state | sessions: new_map}}
  end
end
