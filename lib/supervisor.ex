defmodule Derailed.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Logger.info("Starting Link")
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    Logger.info("Initiating Supervision of Main")
    opts = [strategy: :one_for_one, name: Derailed]

    Supervisor.init([Derailed.Sessions.Supervisor, Derailed.Guilds.Supervisor], opts)
  end
end
