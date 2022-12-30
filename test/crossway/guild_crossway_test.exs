defmodule Derailed.Crossway.Guild.Test do
  use ExUnit.Case
  use Patch
  require Logger

  setup do
    Logger.debug "Setting up test environment"
    # spin up a guild with a random testing id
    {:ok, pid} = GenRegistry.lookup_or_start(Derailed.Guild, "9421837217121", ["9421837217121"])
    {:ok, channel} = GRPC.Stub.connect("localhost:50051")

    on_exit(fn ->
      GenRegistry.stop(Derailed.Guild, "9421837217121")
      GRPC.Stub.disconnect(channel)
    end
    )

    {:ok, gpid: pid, channel: channel}
  end

  test "publish simple message", context do
    request = Derailed.Crossway.Guild.Proto.Publ.new(guild_id: "9421837217121", message: Derailed.Crossway.Guild.Proto.Message.new(event: "TEST", data: "{\"hello\":\"world\"}"))
    {:ok, reply} = Derailed.Crossway.Guild.Proto.Stub.publish(context[:channel], request)
    assert reply.message == "Success"
  end

  test "get guild info", context do
    request = Derailed.Crossway.Guild.Proto.GetGuildInfo.new(guild_id: "9421837217121")
    Derailed.Guild.subscribe(context[:gpid], self())
    {:ok, reply} = Derailed.Crossway.Guild.Proto.Stub.get_guild_info(context[:channel], request)
    assert reply.presences == 1
    assert reply.available == true
  end
end
