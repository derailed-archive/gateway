defmodule Derailed.Guild do
  @moduledoc """
  Process holding data for an online Guild
  """
  require Logger
  use GenServer

  # GenServer API

  def start_link(guild_id) do
    Logger.debug("Spinning up new Guild: #{inspect(guild_id)}")
    GenServer.start_link(__MODULE__, guild_id)
  end

  def init(guild_id) do
    {:ok,
     %{
       id: guild_id,
       members: MapSet.new(),
       presences: Map.new(),
       sessions: MapSet.new()
     }}
  end

  # Session API
  @spec subscribe(pid(), pid()) :: :ok
  def subscribe(pid, session_pid) do
    Logger.debug("Subscribing #{inspect(session_pid)} to #{inspect(pid)}")
    GenServer.cast(pid, {:subscribe, session_pid})
  end

  @spec unsubscribe(pid(), pid()) :: :ok
  def unsubscribe(pid, session_pid) do
    Logger.debug("Unsubscribing #{inspect(session_pid)} to #{inspect(pid)}")
    GenServer.cast(pid, {:unsubscribe, session_pid})
  end

  # shared API between gRPC and Sessions
  @spec publish(pid(), any()) :: :ok
  def publish(pid, message) do
    Logger.debug("Publishing #{inspect(message)} to #{inspect(pid)}")
    GenServer.cast(pid, {:publish, message})
  end

  @spec get_guild_info(pid()) :: {:ok, integer()}
  def get_guild_info(pid) do
    Logger.debug("Getting Guild info for #{inspect(pid)}")
    GenServer.call(pid, :get_guild_info)
  end

  # backend server api
  def handle_cast({:subscribe, pid}, state) do
    {:noreply, %{state | sessions: MapSet.put(state.sessions, pid)}}
  end

  def handle_cast({:unsubscribe, pid}, state) do
    {:noreply, %{state | sessions: MapSet.delete(state.sessions, pid)}}
  end

  def handle_cast({:publish, message}, state) do
    Manifold.send(Enum.to_list(state.sessions), message)
    {:noreply, state}
  end

  def handle_call(:get_guild_info, _from, state) do
    {:reply, {:ok, presence_count: Enum.count(state.presences)}, state}
  end
end
