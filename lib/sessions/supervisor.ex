defmodule Derailed.Session.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Logger.info("Starting Link")
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    Logger.info("Initiating Supervision of Sessions")
    opts = [strategy: :one_for_one, name: Derailed.Session.Registry]

    Supervisor.init([{GenRegistry, worker_module: Derailed.Session.Registry}], opts)
  end
end
