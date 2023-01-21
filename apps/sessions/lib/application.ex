defmodule Derailed.Session.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {GenRegistry, worker_module: Derailed.Session.Registry},
      {Task.Supervisor, name: Derailed.Session.AsyncIO}
    ]

    alias ExHashRing.Ring

    Dotenv.load()

    guild_nodes = String.split(System.get_env("GUILD_NODES"), "/")
    ready_nodes = String.split(System.get_env("READY_NODES"), "/")

    for guild_node <- guild_nodes do
      ZenMonitor.connect(String.to_atom(guild_node))
    end

    for ready_node <- ready_nodes do
      ZenMonitor.connect(String.to_atom(ready_node))
    end

    {:ok, guild_node_ring} = Ring.start_link()
    Ring.add_nodes(guild_node_ring, guild_nodes)

    {:ok, ready_node_ring} = Ring.start_link()
    Ring.add_nodes(ready_node_ring, ready_nodes)

    Application.put_env(:derailed, :guild, guild_node_ring)
    Application.put_env(:derailed, :ready, guild_node_ring)
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sessions.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
