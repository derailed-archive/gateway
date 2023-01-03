defmodule Derailed.Rustacean.Auth do
  use Tesla

  # TODO: Make configurable
  plug Tesla.Middleware.BaseUrl, "http://localhost:4600"
  plug Tesla.Middleware.JSON

  def validate(user_id, token, password) do
    post("/validate", %{user_id: user_id, password: password, token: token})
  end
end
