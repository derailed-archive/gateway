defmodule Derailed.Crossway.User.Test do
  use ExUnit.Case
  use Patch
  require Logger

  setup do
    Logger.debug "Setting up test environment"
    {:ok, channel} = GRPC.Stub.connect("localhost:50052")

    on_exit(fn ->
      GRPC.Stub.disconnect(channel)
    end
    )

    {:ok, channel: channel}
  end

  test "publish simple message", context do
    request = Derailed.Crossway.User.Proto.UPubl.new(user_id: "9421837217121", message: Derailed.Crossway.Proto.Message.new(event: "TEST", data: "{\"hello\":\"world\"}"))
    {:ok, reply} = Derailed.Crossway.User.Proto.Stub.publish(context[:channel], request)
    assert reply.message == "Success"
  end
end
