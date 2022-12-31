defmodule Derailed.Auth do
  @spec authorize(String.t) :: {:ok, map} | {:error, :invalid_token}
  def authorize(token) do
    case Joken.peek_header(token) do
      {:ok, claims} ->
        if not Map.has_key?(claims, "user_id") do
          {:error, :invalid_token}
        end

        if not is_integer(claims[:user_id]) do
          {:error, :invalid_token}
        end

        user = Mongo.find_one(:mongo, "users", %{_id: Map.get(claims, "user_id")})

        case user do
          {:error, _reason} -> {:error, :invalid_token}
          nil -> {:error, :invalid_token}
          _ ->
            signer = Joken.Signer.create("HS256", Map.get(user, "password"))
            res = Joken.Signer.verify(token, signer)

            if elem(res, 0) == :error do
              {:error, :invalid_token}
            end

            {:ok, user}
        end
      {:error, _reason} -> {:error, :invalid_token}
    end
  end
end
