defmodule Derailed.Guild.Registry do
  use GenServer
  require Logger

  def start_link(opts) do
    Logger.info("Starting up Guild Registry")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # client api
  def init(_opts) do
    {:ok, %{}}
  end

  @spec get_guild(String.t) :: pid
  def get_guild(guild_id) do
    GenServer.call(__MODULE__, {:get_guild, guild_id})
  end

  # server api
  def handle_call({:get_guild, guild_id}, _from, state) do
    Logger.debug "Getting Guild from ID #{inspect guild_id}"
    case Map.get(state, guild_id) do
      nil ->
        # guild isn't here
        Logger.debug "Guild #{inspect guild_id} not found, making new GenServer"
        {:ok, guild_pid} = Derailed.Guild.start(guild_id)
        {:reply, guild_pid, Map.put(state, guild_id, guild_pid)}
      guild_pid ->
        # guild is found
        Logger.debug "Guild #{inspect guild_id} found, returning GenServer PID"
        {:reply, guild_pid, state}
    end
  end

end
