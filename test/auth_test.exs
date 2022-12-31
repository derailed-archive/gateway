defmodule Derailed.Auth.Test do
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

  test "verify correct token" do
    {:ok, user} = Derailed.Auth.authorize("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsInVzZXJfaWQiOiIyMTQxMjQyMzQyNDcifQ.eyJ0aW1lIjoxNjcyMzcxMzA3LjMyOTI4MDF9.wC0X62iQDTsGeOphhaW2AlfWxYK2HuTpMbbmAT9GMFA")

    assert Map.has_key?(user, "password")
  end

  test "verify dead token" do
    {:error, reason} = Derailed.Auth.authorize("wudhawubd")

    assert reason == :invalid_token
  end
end
