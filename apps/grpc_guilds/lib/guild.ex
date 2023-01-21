defmodule Derailed.GRPC.Guild do
  alias ExHashRing.Ring
  use GRPC.Server, service: Derailed.GRPC.Guild.Proto.Service

  @doc """
  Process responsible for publishing messages to Guilds
  """
  @spec publish(Derailed.GRPC.Guild.Proto.Publ.t(), GRPC.Server.Stream.t()) ::
          Derailed.GRPC.Guild.Proto.Publr.t()
  def publish(publish_info, _stream) do
    guild_id = publish_info.guild_id

    {:ok, message} = Jsonrs.decode(publish_info.message.data)

    guild_hr = Application.get_env(:derailed_gguilds, :guilds)

    {:ok, node_loc} = Ring.find_node(guild_hr, guild_id)

    task =
      Task.Supervisor.async({Derailed.GRPC.Guild.AsyncIO, String.to_atom(node_loc)}, fn ->
        case GenRegistry.lookup(Derailed.Guild, guild_id) do
          {:ok, guild_pid} ->
            Derailed.Guild.publish(guild_pid, message)

          {:error, :not_found} ->
            self()
        end
      end)

    Task.await(task)

    Derailed.GRPC.Guild.Proto.Publr.new(message: "Success")
  end

  @doc """
  Responsible process for `GET /guilds/.../preview` and Invite Previews.
  Returns the amount of presences and if the Guild is available
  """
  @spec get_guild_info(Derailed.GRPC.Guild.Proto.GetGuildInfo, GRPC.Server.Stream.t()) ::
          Derailed.GRPC.Guild.Proto.RepliedGuildInfo.t()
  def get_guild_info(guild, _stream) do
    guild_id = guild.guild_id

    guild_hr = Application.get_env(:derailed_gguilds, :guild)

    {:ok, node_loc} = Ring.find_node(guild_hr, guild_id)

    task =
      Task.Supervisor.async({Derailed.GRPC.Guild.AsyncIO, String.to_atom(node_loc)}, fn ->
        case GenRegistry.lookup(Derailed.Guild, guild_id) do
          {:ok, guild_pid} ->
            {:ok, presences} = Derailed.Guild.get_guild_info(guild_pid)
            {:ok, presences}

          {:error, :not_found} ->
            {:ok, 0}
        end
      end)

    {:ok, presences} = Task.await(task)

    Derailed.GRPC.Guild.Proto.RepliedGuildInfo.new(
      presences: presences,
      available: presences != 0
    )
  end
end
