defmodule Derailed.Guild.Registry do
  use GenServer
  require Logger

  def start_link(opts) do
    Logger.info('Starting Guild Registry')
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # for the client
  @spec get_guild(String.t) :: pid()
  def get_guild(guild_id) do
    GenServer.call(__MODULE__, {:get, guild_id})
  end

  # backend/server
  def init(_opts) do
    {:ok, %{}}
  end

  def handle_call({:get_guild, guild_id}, _from, state) do
    case Map.get(state, guild_id) do
      nil ->
        # not found, time to make a new process
        {:ok, pid} = Guild.start(guild_id)
        {:reply, pid, Map.put(state, guild_id, pid)}
      gpid ->
        # we found the guild!
        {:reply, gpid, state}
    end
  end
end
