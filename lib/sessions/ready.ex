defmodule Derailed.Ready do
  def generate_session_id() do
    # TODO: Session IDs can collide with eachother
    # maybe a better way to do this is via Snowflakes
    random_data = for _ <- 1..30, do: Enum.random(0..255)

    cap = &(:crypto.hash(:md5, &1))
    random_data
    |> cap.()
    |> Base.encode16(case: :lower)
  end

  @spec check_token(String.t) :: Map
  def check_token(token) do
    # this is kinda jank but basically
    # it just gets the first part of the JWT, the headers
    [encoded_headers, _, _] = String.split token, "."
    {:ok, headers} = encoded_headers |> Base.url_decode64

    {:ok, decoded} = Jason.decode(headers)

    user_id = Map.get(decoded, "user_id")

    user = Mongo.find_one(:mongo, "users", %{_id: user_id})

    if user == nil do
      {:error, nil}
    end

    {:ok, user}
  end

  @spec spin_up(pid, String.t) :: Map
  def spin_up(ws_pid, user_id) do
    user = Mongo.find_one(:mongo, "users", %{_id: user_id})

    if user === nil do
      {:error, :user_is_nil, user_id}
    end

    settings = Mongo.find_one(:mongo, "settings", %{_id: user_id})

    session_pid = Derailed.Session.start(ws_pid, user_id)
    session_id = Derailed.Ready.generate_session_id()
    Derailed.Session.put(session_pid, :session_id, session_id)

    {:reply, user, {settings, session_pid, session_id}}
  end

end
