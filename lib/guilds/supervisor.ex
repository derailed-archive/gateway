defmodule Derailed.Guild.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Logger.info("Starting Link")
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    Logger.info("Initiating Supervision of Guilds")
    opts = [strategy: :one_for_one, name: Derailed.Guild.Registry]

    Supervisor.init([{GenRegistry, worker_module: Derailed.Guild}], opts)
  end
end
