defmodule Derailed.Guilds.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Logger.info("Starting Link")
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    Logger.info("Initiating Supervision")
    opts = [strategy: :one_for_one, name: Guilds]

    Supervisor.init([Guild.Registry], opts)
  end
end
