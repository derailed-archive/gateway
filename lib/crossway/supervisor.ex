defmodule Derailed.Crossway.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Logger.info("Starting Link")
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    Logger.info("Initiating Supervision of The Crossway")
    opts = [strategy: :one_for_one, name: Derailed.Crossway]

    Supervisor.init([GRPC.Server.Supervisor.child_spec(Derailed.Crossway.Guild.Endpoint, 50051)], opts)
  end
end
