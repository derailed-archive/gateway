defmodule Derailed.Ready do
  require Logger

  def get_trace() do
    hash = :crypto.hash(:ripemd160, inspect(self()))
    hash |> Base.encode32(case: :lower)
  end

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
        user_id = Map.get(user, "_id")
        {:ok, reg_pid} = GenRegistry.lookup_or_start(Derailed.Session.Registry, user_id, [user_id])

        {:ok, session_pid} = Derailed.Session.start_link(user_id, pid)
        Derailed.Session.Registry.add_session(reg_pid, session_pid)

        memberships = Mongo.find(:mongo, "members", %{user_id: user_id})

        members = Enum.to_list(memberships)

        guild_ids = MapSet.new(Enum.map(members, fn member ->
          Map.get(member, "guild_id")
        end))
        guild_pids = MapSet.new(Enum.map(members, fn member ->
          guild_id = Map.get(member, "guild_id")
          {:ok, gpid} = GenRegistry.lookup_or_start(Derailed.Guild, guild_id, [guild_id])
          gpid
        end))

        {:ok, user, guild_pids, session_pid, session_id, guild_ids, get_trace()}
    end
  end
end
