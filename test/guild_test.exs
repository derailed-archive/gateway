defmodule Derailed.Guild.Test do
  use ExUnit.Case
  use Patch
  require Logger

  setup do
    # spin up a guild with a random testing id
    {:ok, pid} = GenRegistry.lookup_or_start(Derailed.Guild, "9421837217121", ["21314124"])

    on_exit(fn -> GenRegistry.stop(Derailed.Guild, "9421837217121") end)

    {:ok, gpid: pid}
  end

  test "add and remove subscriber from guild", context do
    Derailed.Guild.subscribe(context[:gpid], self())
    assert Derailed.Guild.exists(context[:gpid], self()) == true
    Derailed.Guild.unsubscribe(context[:gpid], self())
  end

  test "publish message", context do
    Derailed.Guild.subscribe(context[:gpid], self())
    Derailed.Guild.publish(context[:gpid], :hello)
    receive do
      :hello -> Logger.debug("Successfully Got Published Message")
    end
  end
end
