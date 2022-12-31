defmodule Derailed.Crossway.Guild do
  use GRPC.Server, service: Derailed.Crossway.Guild.Proto.Service

  @spec publish(Derailed.Crossway.Guild.Proto.Publ.t, GRPC.Server.Stream.t) :: Derailed.Crossway.Guild.Proto.Publr.t
  def publish(request, _stream) do
    guild_id = request.guild_id
    {:ok, message} = Jason.decode(request.message.data)

    case GenRegistry.lookup(Derailed.Guild, guild_id) do
      {:error, :not_found} -> Derailed.Crossway.Guild.Proto.Publr.new(message: "Success")
      {:ok, guild_pid} ->
        Derailed.Guild.publish(guild_pid, %{t: request.message.event, d: message})
        Derailed.Crossway.Guild.Proto.Publr.new(message: "Success")
    end
  end

  @spec get_guild_info(Derailed.Crossway.Guild.Proto.GetGuildInfo.t, GRPC.Server.Stream.t) :: Derailed.Crossway.Guild.Proto.RepliedGuildInfo.t
  def get_guild_info(request, _stream) do
    guild_id = request.guild_id

    case GenRegistry.lookup(Derailed.Guild, guild_id) do
      {:error, :not_found} -> Derailed.Crossway.Guild.Proto.RepliedGuildInfo.new(presences: 0, available: false)
      {:ok, guild_pid} ->
        presences = Derailed.Guild.get_presence_count(guild_pid)
        Derailed.Crossway.Guild.Proto.RepliedGuildInfo.new(presences: presences, available: true)
    end
  end
end
