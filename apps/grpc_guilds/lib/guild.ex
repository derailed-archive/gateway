defmodule Derailed.GRPC.Guild do
  alias ExHashRing.Ring

  @doc """
  Process responsible for publishing messages to Guilds
  """
  @spec publish(Derailed.GRPC.Guild.Proto.Publ.t(), GRPC.Server.Stream.t()) ::
          Derailed.GRPC.Guild.Proto.Publr.t()
  def publish(publish_info, _stream) do
    guild_id = publish_info.guild_id

    {:ok, message} = Jsonrs.decode(publish_info.message.data)

    guild_hr = FastGlobal.get(:guild)

    {:ok, node_loc} = Ring.find_node(guild_hr, guild_id)

    # TODO: maybe check if the publish is successful or not
    Node.spawn(String.to_atom(node_loc), fn ->
      case GenRegistry.lookup(Derailed.Guild, guild_id) do
        {:ok, guild_pid} ->
          Derailed.Guild.publish(guild_pid, message)
          guild_pid

        {:error, :not_found} ->
          self()
      end
    end)

    Derailed.GRPC.Guild.Proto.Publr.new(message: "Success")
  end
end
