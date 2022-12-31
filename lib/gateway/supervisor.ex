defmodule Derailed.Gateway.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Logger.info("Starting Link")
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    Logger.info("Initiating Supervision of the Gateway")
    opts = [strategy: :one_for_one, name: Derailed.Gateway]

    Supervisor.init(
      [%{
        id: Derailed.Gateway.Connector,
        start: {Derailed.Gateway.Connector, :start_link, []}
      }],
      opts
    )
  end
end
