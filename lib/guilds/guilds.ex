defmodule Derailed.Guilds do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    result = Guilds.Supervisor.start_link(name: Guilds.Supervisor)
    Logger.info "Starting Guild Supervisor with PID: #{inspect(elem(result, 1))}"
    result
  end
end
