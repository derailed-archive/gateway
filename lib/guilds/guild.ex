defmodule Derailed.Guild do
  @moduledoc """
  Processes for Guilds
  """
  use GenServer

  # called only by the registry
  def start(guild_id) do
    GenServer.start(__MODULE__, guild_id)
  end

  # client
  @spec subscribe(pid(), String.t) :: :ok
  def subscribe(pid, uid) do
    GenServer.cast(pid, {:subscribe, uid})
  end

  @spec unsubscribe(pid(), String.t) :: :ok
  def unsubscribe(pid, uid) do
    GenServer.cast(pid, {:unsubscribe, uid})
  end

  @spec publish(pid(), map()) :: :ok
  def publish(pid, message) do
    GenServer.cast(pid, {:publish, message})
  end

  # server/backend
  def init(guild_id) do
    {:ok, %{
      id: guild_id,
      subscribed: MapSet.new()
    }}
  end

  ## calls/casts
  def handle_cast({:subscribe, user_id}, _from, state) do
    subscriptions = state.subscribed
    {:noreply, %{
      state | subscribed: MapSet.put(subscriptions, user_id)
    }}
  end

  def handle_cast({:unsubscribe, user_id}, _from, state) do
    subscriptions = state.subscribed
    {:noreply, %{
      state | subscribed: MapSet.delete(subscriptions, user_id)
    }}
  end

  def handle_cast({:publish, message}, _from, %{subscribed: subscribed}=state) do
    Enum.each(subscribed, &Manifold.send(&1.pid, message))
    {:reply, :ok, state}
  end
end
