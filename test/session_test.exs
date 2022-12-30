defmodule Derailed.Session.Test do
  use ExUnit.Case
  use Patch
  require Logger

  setup do
    # spin up a session with a random testing id
    {:ok, rpid} = GenRegistry.lookup_or_start(Derailed.Session.Registry, "927491278", ["927491278"])
    {:ok, pid} = Derailed.Session.start_link("927491278", self())
    Derailed.Session.Registry.add_session(rpid, pid)
    {:ok, gpid} = GenRegistry.lookup_or_start(Derailed.Guild, "21314124", ["21314124"])

    Derailed.Guild.subscribe(gpid, pid)

    on_exit(fn ->
      GenRegistry.stop(Derailed.Session.Registry, "927491278")
      GenRegistry.stop(Derailed.Guild, "21314124")
    end
    )

    {:ok, spid: pid, gpid: gpid}
  end

  test "publish and receive message", context do
    Derailed.Guild.publish(context[:gpid], %{t: "TEST", d: "HELLO"})
    receive do
      msg -> Logger.debug("Successfully Got Published Message: #{inspect msg}")
    end
  end
end
