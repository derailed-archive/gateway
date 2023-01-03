defmodule Derailed.Auth do
  @spec authorize(String.t) :: {:ok, map} | {:error, :invalid_token}
  def authorize(token) do
    [encoded_uid, _, _] = String.split token, "."
    {:ok, user_id} = encoded_uid |> Base.url_decode64

    case Mongo.find_one(:mongo, "users", %{_id: user_id}) do
      nil -> {:error, :invalid_token}
      {:error, _reason} -> {:error, :invalid_token}
      doc ->
        user = Map.new(doc)
        {:ok, resp} = Derailed.Rustacean.Auth.validate(user_id, token, Map.get(user, "password"))
        m = Map.new(resp)
        is_valid = Map.get(m, "is_valid")

        case is_valid do
          false ->
            {:error, :invalid_token}
          true ->
            {:ok, user}
        end
    end
  end
end
