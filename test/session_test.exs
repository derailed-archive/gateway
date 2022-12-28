defmodule Derailed.Session.Test do
  use ExUnit.Case
  use Patch
  require Logger

  setup do
    # spin up a session with a random testing id
    {:ok, pid} = GenRegistry.lookup_or_start(Derailed.Session, "abcde", [self()])
    {:ok, gpid} = GenRegistry.lookup_or_start(Derailed.Guild, "21314124", ["21314124"])

    Derailed.Guild.subscribe(gpid, pid)

    on_exit(fn ->
      GenRegistry.stop(Derailed.Session, "abcde")
      GenRegistry.stop(Derailed.Guild, "21314124")
    end
    )

    {:ok, spid: pid, gpid: gpid}
  end

  test "publish and receive message", context do
    Derailed.Guild.publish(context[:gpid], {:event, "hello"})
    receive do
      "hello" -> Logger.debug("Successfully Got Published Message")
    end
  end
end
