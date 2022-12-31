defmodule Derailed do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info "Starting Derailed Supervisor"
    Derailed.Supervisor.start_link(name: Derailed.Supervisor)
  end
end
