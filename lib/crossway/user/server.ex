defmodule Derailed.Crossway.User do
  use GRPC.Server, service: Derailed.Crossway.User.Proto.Service

  @spec publish(Derailed.Crossway.User.Proto.UPubl.t, GRPC.Server.Stream.t) :: Derailed.Crossway.User.Proto.UPublr.t
  def publish(request, _stream) do
    case GenRegistry.lookup(Derailed.Session.Registry, request.user_id) do
      {:error, :not_found} -> Derailed.Crossway.User.Proto.UPublr.new(message: "Success")
      {:ok, pid} ->
        {:ok, message} = Jason.decode(request.message.data)
        for session_pid <- Derailed.Session.Registry.get_sessions(pid) do
          Manifold.send(session_pid, %{t: request.message.event, d: message})
        end
    end
  end
end
