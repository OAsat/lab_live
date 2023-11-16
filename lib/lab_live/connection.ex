defmodule LabLive.Connection do
  @moduledoc """
  Sever to connect to an instrument.
  """
  use GenServer
  alias LabLive.Connection.Method

  @type resource() :: any()
  @type sleep_after_reply() :: non_neg_integer() | nil
  @type method() :: Method.Pyvisa | Method.Tcp | Method.Dummy
  @type method_opts() :: Method.Pyvisa.opts() | Method.Tcp.opts() | Method.Dummy.opts()

  defmodule State do
    @moduledoc false
    defstruct [:name, :resource, :method, :sleep_after_reply]
  end

  @type state() :: %State{
          name: GenServer.name(),
          resource: resource(),
          method: method(),
          sleep_after_reply: sleep_after_reply()
        }

  @type opt() ::
          {:name, GenServer.name()}
          | {:sleep_after_reply, sleep_after_reply()}
          | {:method, method()}
          | {:method_opts, method_opts()}

  @type opts() :: [opt()]

  @spec start_link(opts()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @spec reset(pid(), opts()) :: :ok
  def reset(pid, opts) do
    GenServer.cast(pid, {:reset, opts})
  end

  @spec read(pid(), String.t()) :: String.t()
  def read(pid, message) when is_binary(message) do
    GenServer.call(pid, {:read, message})
  end

  @spec write(pid(), String.t()) :: :ok
  def write(pid, message) when is_binary(message) do
    GenServer.cast(pid, {:write, message})
  end

  @impl GenServer
  def init(opts) do
    {:ok, init_state(opts)}
  end

  @impl GenServer
  def terminate(reason, %State{} = state) do
    :ok = state.method.terminate(reason, state.resource)
    sleep(state.sleep_after_reply)
  end

  @impl GenServer
  def handle_call({:read, message}, from, %State{} = state) do
    answer = state.method.read(message, state.resource)
    GenServer.reply(from, answer)
    execute_telemetry(:read, message, answer, state)
    sleep(state.sleep_after_reply)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:write, message}, %State{} = state) do
    :ok = state.method.write(message, state.resource)
    execute_telemetry(:write, message, nil, state)
    sleep(state.sleep_after_reply)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:reset, opts}, %State{} = state) do
    :ok = state.method.terminate(:normal, state.resource)
    {:noreply, init_state(opts)}
  end

  defp init_state(opts) do
    method = opts[:method] || raise(":method option is required.")

    %State{
      name: opts[:name],
      resource: method.init(opts[:method_opts]),
      method: Application.get_env(:lab_live, :method, method),
      sleep_after_reply: opts[:sleep_after_reply]
    }
  end

  defp execute_telemetry(event, query, answer, state) do
    :telemetry.execute(
      [:lab_live, :instrument, event],
      %{query: query, answer: answer, state: state}
    )
  end

  defp sleep(nil), do: nil
  defp sleep(sleep_time) when sleep_time > 0, do: Process.sleep(sleep_time)
end
