defmodule Derailed.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Logger.info("Starting Link")
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    Logger.info("Initiating Supervision of Derailed")
    opts = [strategy: :one_for_one, name: Derailed]

    Dotenvy.source([".env", System.get_env()])

    Supervisor.init(
      [
        Derailed.Guild.Supervisor,
        Derailed.Session.Supervisor,
        Derailed.Crossway.Supervisor,
        {Mongo, name: :mongo, database: "derailed", pool_size: 2, url: Dotenvy.env!("MONGODB_URI", :string!)}
      ],
        opts
    )
  end
end
