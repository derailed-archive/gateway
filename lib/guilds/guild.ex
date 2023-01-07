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

  @spec publish_presence(pid(), String.t) :: :ok
  def publish_presence(pid, user_id) do
    GenServer.cast(pid, {:publish_presence, user_id})
  end

  @spec offline(pid(), String.t) :: :ok
  def offline(pid, user_id) do
    GenServer.cast(pid, {:offline, user_id})
  end

  @spec delete_presence(pid(), String.t) :: :ok
  def delete_presence(pid, user_id) do
    GenServer.cast(pid, {:delete_presence, user_id})
  end

  @spec get_guild_members(pid(), pid(), boolean()) :: :ok
  def get_guild_members(pid, session_pid, offline) do
    GenServer.cast(pid, {:get_guild_members, session_pid, offline})
  end

  @spec exists(pid(), pid()) :: boolean
  def exists(pid, session_pid) do
    GenServer.call(pid, {:exists, pid, session_pid})
  end

  @spec get_presence_count(pid()) :: integer
  def get_presence_count(pid) do
    GenServer.call(pid, :get_presence_count)
  end

  @spec get_id(pid()) :: String.t
  def get_id(pid) do
    GenServer.call(pid, :get_id)
  end

  # server
  def init(guild_id) do
    {:ok, %{
      id: guild_id,
        sessions: MapSet.new(),
        presences: Map.new(),
      }}
  end

  def handle_call({:exists, pid, session_pid}, _from, state) do
    Logger.debug "Checking if session id #{inspect pid} exists"
    {:reply, MapSet.member?(state.sessions, session_pid), state}
  end

  def handle_call(:get_presence_count, _from, state) do
    Logger.debug "Getting Presence count for Guild #{state.id}"
    presence_count = Enum.count_until(state.presences, 1000)
    {:reply, presence_count, state}
  end

  def handle_call(:get_id, _from, state) do
    {:reply, state.id, state}
  end

  def handle_cast({:subscribe, session_pid}, state) do
    Logger.debug("Subscribing #{inspect session_pid} to #{state.id}")
    {:noreply, %{state | sessions: MapSet.put(state.sessions, session_pid)}}
  end

  def handle_cast({:unsubscribe, session_pid}, state) do
    Logger.debug("Unsubscribing #{inspect session_pid} from #{state.id}")
    new_map = MapSet.delete(state.sessions, session_pid)

    if Enum.empty?(new_map) do
      Logger.debug "Stopping Guild #{state.id}"
      GenRegistry.stop(Derailed.Guild, state.id)
    end

    {:noreply, %{state | sessions: new_map}}
  end

  def handle_cast({:publish, message}, state) do
    Logger.debug "Publishing message to #{state.id}: #{inspect message}"

    Enum.each(state.sessions, &Manifold.send(&1, message))
  end

  def handle_cast({:publish_presence, user_id}, state) do
    Logger.debug "Publishing Presence of #{user_id}"

    if Map.has_key?(state.presences, user_id) do
      {:noreply, state}
    end

    presence = Mongo.find_one(:mongo, "presences", %{_id: user_id})

    case presence do
      {:error, _reason} -> {:noreply, state}
      nil ->
        settings = Map.new(Mongo.find_one(:mongo, "settings", %{_id: user_id}))
        status = Map.get(settings, "status")

        if status != "invisible" do
          presence = Map.new()
          presence = Map.put(presence, "_id", user_id)
          presence = Map.put(presence, "device", "web")
          presence = Map.put(presence, "activities", [])
          presence = Map.put(presence, "status", status)
          presence = Map.put(presence, "guild_id", state.id)
          Mongo.insert_one!(:mongo, "presences", presence)

          Derailed.Guild.publish(self(), %{t: "PRESENCE_UPDATE", d: presence})

          if Map.has_key?(state.presences, user_id) do
            {:noreply, %{state | presences: Map.replace(state.presences, user_id, presence)}}
          else
            {:noreply, %{state | presences: Map.put(state.presences, user_id, presence)}}
          end
        end
      obj ->
          presence = Map.new(presence)

          Derailed.Guild.publish(self(), %{d: presence, t: "PRESENCE_UPDATE",})

          if Map.has_key?(state.presences, user_id) do
            {:noreply, %{state | presences: Map.replace(state.presences, user_id, presence)}}
          else
            {:noreply, %{state | presences: Map.put(state.presences, user_id, presence)}}
          end
    end
  end

  def handle_cast({:offline, user_id}, state) do
    Logger.debug "Offlining User #{user_id}"

    presence = Map.get(state.presences, user_id)

    if presence == nil do
      {:noreply, state}
    end

    presences = Map.delete(state.presences, user_id)
    presence = Map.replace(presence, "status", "invisible")

    Mongo.update_one!(:mongo, "presences", %{_id: user_id}, presence)

    Derailed.Guild.publish(self(), %{d: %{presence: presence}, t: "PRESENCE_UPDATE"})

    {:noreply, %{state | presences: presences}}
  end

  def handle_cast({:delete_presence, user_id}, state) do
    {:noreply, %{state | presences: Map.delete(state.presences, user_id)}}
  end

  def handle_cast({:get_guild_members, session_pid, offline}, state) do
    presences = state.presences

    # TODO: this can be sped up by storing the guilds members prematurely
    online_members = Enum.map(presences, fn user_id ->
      member = Mongo.find_one(:mongo, "members", %{user_id: user_id, guild_id: state.id})
      member = Map.new(member)
      Map.delete(member, "_id")
    end)

    if offline do
      offline_members = Enum.map(Enum.to_list(Mongo.find(:mongo, "presences", %{guild_id: state.id, status: "invisible"})), fn presence ->
        p = Map.new(presence)
        member = Mongo.find_one(:mongo, "members", %{user_id: Map.get(p, "user_id"), guild_id: state.id})
        member = Map.new(member)
        Map.delete(member, "_id")
      end)

      members = Enum.concat(online_members, offline_members)
      Manifold.send(session_pid, %{d: %{guild_id: state.id, members: members}, t: "GUILD_MEMBER_CHUNK"})

      {:noreply, state}
    else
      Manifold.send(session_pid, %{d: %{guild_id: state.id, members: online_members}, t: "GUILD_MEMBER_CHUNK"})

      {:noreply, state}
    end
  end
end
