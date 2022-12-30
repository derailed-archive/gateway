defmodule Derailed.Ready.Test do
  use ExUnit.Case
  use Patch
  require Logger

  setup do
    Logger.debug "Creating User"
    try do
      Mongo.insert_one!(:mongo, "users", %{_id: "214124234247", password: "21wa"})
    rescue
      _ in Mongo.WriteError -> {:ok, good: :ok}
    end

    on_exit(fn -> Mongo.delete_one(:mongo, "users", %{_id: "214124234247"}) end)

    {:ok, good: :ok}
  end

  test "invalid ready" do
    assert Derailed.Ready.handle_ready("dwadwain28", self()) == {:error, :invalid_auth}
  end

  test "valid ready" do
    {:ok, user, guild_pids, _session_pid, session_id} = Derailed.Ready.handle_ready("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsInVzZXJfaWQiOiIyMTQxMjQyMzQyNDcifQ.eyJ0aW1lIjoxNjcyMzcxMzA3LjMyOTI4MDF9.wC0X62iQDTsGeOphhaW2AlfWxYK2HuTpMbbmAT9GMFA", self())
    assert user != nil
    assert guild_pids == MapSet.new()
    GenRegistry.stop(Derailed.Session, session_id)
  end
end
