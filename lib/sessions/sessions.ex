defmodule Derailed.Sessions do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    result = Derailed.Sessions.Supervisor.start_link(name: Sessions.Supervisor)
    Logger.info "Starting Sessions Supervisor with PID: #{inspect(elem(result, 1))}"
    result
  end
end
