defmodule Derailed.Guild.Entry do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info "Starting Guild Supervisor"
    Derailed.Guild.Supervisor.start_link(name: Derailed.Guild.Supervisor)
  end
end
