defmodule Derailed.GRPC.Users.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GRPC.Server.Supervisor.child_spec(Derailed.GRPC.User.Endpoint, 50052),
      {Task.Supervisor, name: Derailed.GRPC.User.AsyncIO}
    ]

    alias ExHashRing.Ring

    Dotenv.load()

    session_nodes = String.split(System.get_env("SESSION_NODES"), "/")

    for session_node <- session_nodes do
      ZenMonitor.connect(String.to_atom(session_node))
    end

    {:ok, session_node_ring} = Ring.start_link()
    Ring.add_nodes(session_node_ring, session_nodes)

    Application.put_env(:derailed_gusers, :session, session_node_ring)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Derailed.Users.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
