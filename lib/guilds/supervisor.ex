defmodule Derailed.Guilds.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Logger.info("Starting Link")
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    Logger.info("Initiating Supervision of Guilds")
    opts = [strategy: :one_for_one, name: Derailed.Guilds]

    Supervisor.init([Derailed.Guild.Registry], opts)
  end
end
