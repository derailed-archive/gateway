defmodule Derailed.Sessions.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Logger.info("Starting Link")
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    Logger.info("Initiating Supervision of Sessions")
    opts = [strategy: :one_for_one, name: Derailed.Sessions]

    Dotenvy.source([".env", System.get_env()])

    Supervisor.init(
      [
        Derailed.Session.Registry,
        %{
          id: Mongo,
          start: {Mongo, :start_link, [[name: :mongo, url: Dotenvy.env!("MONGO_URI"), database: "derailed", pool_size: 3]]}
         },
        ],
        opts
    )
  end
end
