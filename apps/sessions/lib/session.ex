defmodule Derailed.Session do
  use GenServer
  require Logger
  import Ecto.Query

  @spec start_link(pid(), pid()) :: {:ok, pid}
  def start_link(session_id, ws_pid) do
    Logger.debug("Spinning up new Session: #{inspect(session_id)}/#{inspect(ws_pid)}")
    GenServer.start_link(__MODULE__, {session_id, ws_pid})
  end

  def init({session_id, ws_pid, user_id}) do
    {:ok,
     %{
       id: session_id,
       guild_pids: Map.new(),
       ws_pid: ws_pid,
       user_id: user_id
     }}
  end

  def sync_guilds(pid) do
    GenServer.cast(pid, :sync_guilds)
  end

  # server
  def handle_cast(:sync_guilds, state) do
    joined_guild_member_objects_query =
      from(m in Derailed.Database.Member,
        where: m.user_id == ^state.user_id
      )

    # this isn't really complex but all it does is:
    # query the db and maps the returned objects to only have the guild ids
    joined_guild_member_objects = Derailed.Database.Repo.all(joined_guild_member_objects_query)
    guild_ids = Enum.map(joined_guild_member_objects, fn gm -> gm.guild_id end)

    Enum.each(guild_ids, fn guild_id ->
      get_guild_query =
        from(g in Derailed.Database.Guild,
          where: g.id == ^guild_id
        )

      guild_object = Map.new(Derailed.Database.Repo.one(get_guild_query))
      Manifold.send(state.ws_pid, %{t: "GUILD_CREATE", d: guild_object})
    end)

    {:noreply, state}
  end
end
