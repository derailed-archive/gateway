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

  def encode(data) do
    e = Map.new(data)
    {:ok, d} = Jason.encode(e)
    d
  end

  def websocket_init(_req) do
    hb_timer(45_000)

    {:reply, {:text, encode(
      %{
        _trace: get_trace(),
        d: %{
          heartbeat_interval: 45_000
        },
        s: 0,
        op: 2,
      }
    )}, %{
      hb: false,
      ops: MapSet.new([0, 1, 2]),
      s: 0,
      guilds: MapSet.new(),
      session: nil,
      id: nil,
      uid: nil,
      ready: false,
    }}
  end

  def websocket_handle({:text, content}, state) do
    case Jason.decode(content) do
      {:error, _reason} ->
        {:reply, {:close, 4000, "Bad Packet Sent"}, state}
      {:ok, data} ->
        case Map.get(data, "op") do
          nil ->
            {:reply, {:close, 4000, "Bad Message Sent"}, state}
          op ->
            if not MapSet.member?(state.ops, op) do
              {:reply, {:close, 4001, "Bad OP code"}, state}
            end
            case Map.get(data, "d", Map) do
              Map -> {:reply, {:close, 4003, "Invalid Data"}, state}
              d -> handle_op({get_name(op), d}, state)
            end
        end
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

    {:reply, {:text, encode(%{s: 0, d: nil, op: 3})}, %{state | hb: true, s: 0}}
  end

  def handle_op({:identify, data}, state) do
    token = Map.get(data, "token")
    if token == nil do
      {:reply, {:close, 4004, "Invalid Authorization"}, state}
    end

    case Derailed.Ready.handle_ready(token, self()) do
      {:error, _reason} -> {:reply, {:close, 4004, "Invalid Authorization"}, state}
      {:ok, user, guild_pids, session_pid, session_id, guild_ids, trace} ->
        user = Map.new(user)
        settings = Mongo.find_one(:mongo, "settings", %{_id: Map.get(user, "_id")})

        Manifold.send(self(), :send_guilds)
        {:reply, {:text, encode(%{
          op: 4,
          d: %{
            _trace: trace,
            session_id: session_id,
            unavailable_guilds: guild_ids,
            user: user,
            settings: settings,
          }
        })}, %{state | guilds: guild_pids, session: session_pid, id: session_id, uid: Map.get(user, "_id")}}
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
    Map.put(guild, "available", true)

    s = state.s + 1
    {:reply, {:text, encode(%{d: guild, s: s, t: "GUILD_CREATE", op: 0})}, %{state | s: s}}
  end

  def websocket_info(:look_heartbeat, state) do
    if state.hb == false do
      {:reply, {:close, 4006, "Heartbeat time passed"}, state}
    end

    hb_timer(45_000)
    {:ok, %{state | hb: false}}
  end

  def websocket_info(data, state) do
    t = Map.get(data, "t")
    s = state.s + 1
    data = Map.put(data, "op", 0)
    data = Map.put(data, "s", s)

    if is_nil(t) do
      {:ok, state}
    end

    case t do
      "GUILD_CREATE" ->
        guild_id = Map.get(Map.get(data, "d"), "_id")
        {:ok, pid} = GenRegistry.lookup_or_start(Derailed.Guild, guild_id, [guild_id])
        {:reply, {:text, encode(data)}, %{state | s: s, guilds: MapSet.put(state.guilds, pid)}}
      "USER_DELETE" -> {:reply, {:close, 4005, "User Deleted"}, state}
      "GUILD_DELETE" ->
        case GenRegistry.lookup(Derailed.Guild, Map.get(Map.get(data, "d"), "guild_id")) do
          {:error, :not_found} -> {:reply, {:text, encode(data)}, %{state | s: s}}
          {:ok, pid} ->
            Derailed.Guild.unsubscribe(pid, state.session)
            {:reply, {:text, encode(data)}, %{state | s: s, guilds: MapSet.delete(state.guilds, pid)}}
        end
        _ ->
          {:reply, {:text, encode(data)}, state}
    end

    {:reply, {:text, encode(data)}, %{state | s: s}}
  end

  def terminate(_reason, _req, state) do
    if state.ready == false do
      :ok
    end

    for pid <- state.guilds do
      Derailed.Guild.unsubscribe(pid, state.session)
    end

    case GenRegistry.lookup(Derailed.Session.Registry, state.uid) do
      {:error, _reason} -> :ok
      {:ok, reg_pid} ->
        Derailed.Session.Registry.remove_session(reg_pid, state.session)

        GenServer.stop(state.session, :shutdown)
        :ok
    end
  end
end
