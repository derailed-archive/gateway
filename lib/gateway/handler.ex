defmodule Derailed.Gateway do
  @behaviour :cowboy_websocket
  require Logger

  def init(req, state) do
    Logger.debug "New client: #{inspect req}"

    {:cowboy_websocket, req, state}
  end

  def get_trace() do
    hash = :crypto.hash(:ripemd160, inspect(self()))
    hash |> Base.encode32(case: :lower)
  end

  def form_message(op, type, data, state) do
    {:ok, encoded} = Jsonrs.encode(%{"op" => op, "t" => type, "s" => state.s + 1, "d" => data})
    {:text, encoded}
  end

  def form_message(op, data, state) do
    trace = get_trace()
    {:ok, encoded} = Jsonrs.encode(%{"op" => op, "s" => state.s + 1, "d" => data, "_trace" => trace})
    {:text, encoded}
  end

  @spec form_message(any, any) :: {:text, binary}
  def form_message(op, data) do
    trace = get_trace()
    {:ok, encoded} = Jsonrs.encode(%{"op" => op, "s" => 0, "d" => data, "_trace" => trace})
    {:text, encoded}
  end

  @spec hb_timer(integer()) :: reference()
  def hb_timer(interval) do
    :erlang.send_after(interval + 1000, self(), :look_heartbeat)
  end

  @spec get_opcode(atom()) :: integer()
  def get_opcode(name) do
    %{
      heartbeat: 0,
      identify: 1,
    }[name]
  end

  @spec get_name(integer()) :: atom()
  def get_name(op) do
    %{0 => :heartbeat,
      1 => :identify,}[op]
  end

  def payloaded(op, data) do
    %{op: op, d: data}
  end

  def random_hb_time() do
    Enum.random(42_000..48_000)
  end

  def websocket_init(_req) do
    hb_time = random_hb_time()
    hb_timer(hb_time)

    {:reply, form_message(2, %{"heartbeat_interval" => hb_time}), %{
      hb: false,
      ops: MapSet.new([0, 1, 2]),
      s: 0,
      guilds: MapSet.new(),
      session: nil,
      id: nil,
      uid: nil,
      ready: false,
      hb_time: hb_time
    }}
  end

  def websocket_handle({:text, content}, state) do
    case Hammer.check_rate(state.id, 60_000, 50) do
      {:allow, _count} ->
        case Jsonrs.decode(content, [lean: true]) do
          {:error, _reason} ->
            {:reply, {:close, 4000, "Bad packet"}, state}
          {:ok, data} ->
            case Map.get(data, "op") do
              nil ->
                {:reply, {:close, 4000, "Bad message"}, state}
              op ->
                if not MapSet.member?(state.ops, op) do
                  {:reply, {:close, 4001, "Bad OP code"}, state}
                end
                case Map.get(data, "d", Map) do
                  Map -> {:reply, {:close, 4003, "Invalid data"}, state}
                  d -> handle_op({get_name(op), d}, state)
                end
            end
        end
      {:deny, _limit} ->
        {:reply, {:close, 4007, "Rate limit passed"}, state}
    end
  end

  def websocket_handle(_any_frame, state) do
    {:ok, state}
  end

  def handle_op({:heartbeat, data}, state) do
    if state.hb == true do
      {:reply, {:close, 4002, "Already Heartbeated"}, state}
    end

    s = data

    if s != nil and not is_integer(s) do
      {:reply, {:close, 4004, "Invalid Data"}, state}
    end

    if s != state.s do
      {:reply, {:close, 4004, "Invalid Data"}, state}
    end

    {:reply, form_message(3, 0), %{state | hb: true, s: 0}}
  end

  def handle_op({:identify, data}, state) do
    token = Map.get(data, "token")
    if token == nil do
      {:reply, {:close, 4004, "Invalid Authorization"}, state}
    end

    case Derailed.Ready.handle_ready(token, self()) do
      {:error, _reason} -> {:reply, {:close, 4004, "Invalid Authorization"}, state}
      {:ok, user, guild_pids, session_pid, session_id, guild_ids, _trace} ->
        user = Map.new(user)
        settings = Mongo.find_one(:mongo, "settings", %{_id: Map.get(user, "_id")})

        Manifold.send(self(), :send_guilds)
        {:reply, form_message(4, %{
            "session_id" => session_id,
            "unavailable_guilds" => guild_ids,
            "user" => user,
            "settings" => settings,
        }, state), %{state | guilds: guild_pids, session: session_pid, id: session_id, uid: Map.get(user, "_id"), s: state.s + 1}}
    end
  end

  def websocket_info(:send_guilds, state) do
    guild_pids = state.guilds

    for pid <- guild_pids do
      guild_id = Derailed.Guild.get_id(pid)

      guild = Mongo.find_one(:mongo, "guilds", %{_id: guild_id})

      case guild do
        nil -> MapSet.delete(guild_pids, pid)
        {:error, reason} -> {:error, reason}
        guild ->
          Manifold.send(self(), {:send_guild, guild, pid})
      end

      if is_nil(guild) do
        ^guild_pids = MapSet.delete(guild_pids, pid)
      end
    end

    {:ok, %{state | guilds: guild_pids}}
  end

  def websocket_info({:send_guild, guild, guild_pid}, state) do
    Derailed.Guild.subscribe(guild_pid, state.session)
    guild = Map.put(guild, "available", true)

    guild = Map.put(guild, "channels", Enum.to_list(Mongo.find(:mongo, "channels", %{guild_id: Map.get(guild, "_id")})))
    guild = Map.put(guild, "roles", Enum.to_list(Mongo.find(:mongo, "roles", %{guild_id: Map.get(guild, "_id")})))

    s = state.s + 1
    {:reply, form_message(0, "GUILD_CREATE", guild, state), %{state | s: s}}
  end

  def websocket_info(:look_heartbeat, state) do
    if state.hb == false do
      {:reply, {:close, 4006, "Heartbeat time passed"}, state}
    end

    hb_timer(state.hb_time)
    {:ok, %{state | hb: false}}
  end

  def websocket_info(data, state) do
    t = Map.get(data, "t")
    d = Map.get(data, "d")
    s = state.s + 1
    data = Map.put(data, "op", 0)
    data = Map.put(data, "s", s)

    case t do
      "GUILD_CREATE" ->
        guild_id = Map.get(Map.get(data, "d"), "_id")
        {:ok, pid} = GenRegistry.lookup_or_start(Derailed.Guild, guild_id, [guild_id])
        Manifold.send(self(), {:send_guild, d, pid})
        Derailed.Guild.publish_presence(pid, state.uid)
        {:ok, state}
      "USER_DELETE" -> {:reply, {:close, 4005, "User Deleted"}, state}
      "GUILD_DELETE" ->
        case GenRegistry.lookup(Derailed.Guild, Map.get(Map.get(data, "d"), "guild_id")) do
          {:error, :not_found} -> {:reply, form_message(0, t, d, state), %{state | s: s}}
          {:ok, pid} ->
            Derailed.Guild.unsubscribe(pid, state.session)
            {:reply, form_message(0, t, d, state), %{state | s: s, guilds: MapSet.delete(state.guilds, pid)}}
        end
      nil ->
        {:ok, state}
      _ ->
          {:reply, form_message(0, t, d, state), %{state | s: s}}
    end
  end

  def terminate(_reason, _req, state) do
    if state.ready == false do
      :ok
    end

    case GenRegistry.lookup(Derailed.Session.Registry, state.uid) do
      {:error, _reason} -> :ok
      {:ok, reg_pid} ->
        for pid <- state.guilds do
          Derailed.Guild.unsubscribe(pid, state.session)
          if Derailed.Session.Registry.offlineable(reg_pid, state.session) == true do
            try do
              Derailed.Guild.offline(pid, state.uid)
            rescue
              _ in FunctionClauseError ->
                  Derailed.Session.Registry.remove_session(reg_pid, state.session)

                  GenServer.stop(state.session, :shutdown)
                  :ok
            end
          end
        end

        Derailed.Session.Registry.remove_session(reg_pid, state.session)

        GenServer.stop(state.session, :shutdown)
        :ok
    end
  end
end
