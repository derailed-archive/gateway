defmodule Derailed.Session.Entry do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info "Starting Session Supervisor"
    Derailed.Session.Supervisor.start_link(name: Derailed.Session.Supervisor)
  end
end
