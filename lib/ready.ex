defmodule Derailed.Ready do
  require Logger

  def generate_session_id() do
    # TODO: add a way for session ids not to collide, or
    # transfer session ids to pure snowflakes instead
    random_data = for _ <- 1..30, do: Enum.random(0..255)

    cap = &(:crypto.hash(:md5, &1))
    random_data
    |> cap.()
    |> Base.encode16(case: :lower)
  end

  def handle_ready(token, pid) do
    res = Derailed.Auth.authorize(token)

    case res do
      {:error, _reason} -> {:error, :invalid_auth}
      {:ok, user} ->
        user = Map.new(user)
        user = Map.delete(user, "password")

        session_id = generate_session_id()
        user_id = Map.get(user, "id")
        {:ok, reg_pid} = GenRegistry.lookup_or_start(Derailed.Session.Registry, user_id, [user_id])

        {:ok, session_pid} = Derailed.Session.start_link(user_id, pid)
        Derailed.Session.Registry.add_session(reg_pid, session_pid)

        memberships = Mongo.find(:mongo, "members", %{user_id: user_id})

        membership_list = Enum.to_list(memberships)
        guild_pids = MapSet.new()
        guild_ids = MapSet.new()

        for member <- membership_list do
          guild_id = Map.get(member, "guild_id")
          MapSet.put(guild_ids, guild_id)
          gpid = GenRegistry.lookup_or_start(Derailed.Guild, guild_id, [guild_id])
          MapSet.put(guild_pids, gpid)
          Derailed.Guild.subscribe(gpid, session_pid)
        end

        {:ok, user, guild_pids, session_pid, session_id, guild_ids}
    end
  end
end
