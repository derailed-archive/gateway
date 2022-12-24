defmodule Derailed.Session do
  @moduledoc """
  GenServer for a single user Session
  """
  use GenServer
  require Logger

  defmodule Struct do
    @moduledoc """
    Defines a stucture of data to be hold to a state
    object.
    """
    defstruct [:session_id, :token, :user_id, :events,
               :large, :ws_pid, :presence, :guild_pids]
  end

  def start(pid, user_id) do
    GenServer.start(
      __MODULE__,
      %Struct{
        user_id: user_id,
        events: [],
        ws_pid: pid,
        presence: nil,
        guild_pids: MapSet.new()
      }
    )
  end

  def init(state) do
    {:ok, state}
  end

  # client
  @spec get(pid(), atom()) :: Types.state_type()
  def get(pid, key) do
    # Logger.info "state get: #{inspect pid} -> #{inspect key}"
    GenServer.call(pid, {:get, key})
  end

  @spec put(pid(), atom(), Types.state_type()) :: :ok
  def put(pid, key, value) do
    # Logger.info "state put #{inspect pid} -> #{inspect key} : #{inspect value}"
    GenServer.cast(pid, {:put, key, value})
  end

  # internal
  def handle_call({:get, key}, _from, state) do
    res = Map.get(state, key)
    Logger.info "HANDLING state get: #{inspect key} : #{inspect res}"
    {:reply, res, state}
  end

  def handle_cast({:put, key, value}, state) do
    Logger.info "HANDLING state put #{inspect key} : #{inspect value}"
    new_state = Map.put(state, key, value)
    {:noreply, new_state}
  end
end
