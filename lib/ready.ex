defmodule Derailed.Ready do
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
        session_id = generate_session_id()
        {:ok, pid} = GenRegistry.start(Derailed.Session, session_id, [pid])

        memberships = Mongo.find(:mongo, "users", %{user_id: Map.get(user, "id")})

        membership_list = Enum.to_list(memberships)
        guild_pids = MapSet.new()

        for member <- membership_list do
          guild_id = Map.get(member, "guild_id")
          gpid = GenRegistry.lookup_or_start(Derailed.Guild, guild_id, [guild_id])
          MapSet.put(guild_pids, gpid)
          Derailed.Guild.subscribe(pid, pid)
        end

        {:ok, user, guild_pids, pid, session_id}
    end
  end
end
