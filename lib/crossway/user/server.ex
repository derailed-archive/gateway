defmodule Derailed.Crossway.User do
  use GRPC.Server, service: Derailed.Crossway.User.Proto.Service

  @spec publish(Derailed.Crossway.User.Proto.UPubl.t, GRPC.Server.Stream.t) :: Derailed.Crossway.User.Proto.UPublr.t
  def publish(request, _stream) do
    user_id = request.user_id
    case GenRegistry.lookup(Derailed.Session.Registry, user_id) do
      {:error, :not_found} -> Derailed.Crossway.User.Proto.UPublr.new(message: "Success")
      {:ok, pid} ->
        {:ok, message} = Jsonrs.decode(request.message.data)
        Enum.each(Derailed.Session.Registry.get_sessions(pid), fn session_pid ->
          Manifold.send(session_pid, %{"d" => message, "t" => request.message.event})
        end)
        Derailed.Crossway.User.Proto.UPublr.new(message: "Success")
    end
  end
end
