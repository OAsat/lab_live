defmodule LabLive.Instrument.Port do
  @moduledoc """
  Sever to communicate with measurement instrument.
  """
  use GenServer

  defmodule State do
    @moduledoc false
    defstruct [:resource, :impl, :opts]
  end

  @type impl() :: module()

  @type state() :: %State{
          resource: any(),
          impl: impl(),
          opts: opts()
        }

  @type opt() ::
          {:name, GenServer.name()}
          | {:key, atom()}
          | {:sleep_after, non_neg_integer()}
          | {:type, impl()}
          | {atom(), any()}

  @type opts() :: [opt()]

  @impl GenServer
  def init(opts) do
    {:ok, init_state(opts)}
  end

  defp init_state(opts) do
    if not Keyword.has_key?(opts, :type) do
      raise ":type option is required."
    end

    impl = Application.get_env(:lab_live, :inst_type, opts[:type])
    %State{resource: impl.init(opts), impl: impl, opts: opts}
  end

  @impl GenServer
  def terminate(reason, %State{opts: opts, impl: impl, resource: resource}) do
    :ok = impl.terminate(reason, resource)
    sleep(opts)
  end

  @impl GenServer
  def handle_call({:read, message}, from, %State{} = state) do
    {answer, info} = state.impl.read(message, state.resource)

    GenServer.reply(from, answer)
    :ok = state.impl.after_reply(info, state.resource)

    execute_telemetry(:read, message, answer, state)
    sleep(state.opts)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:write, message}, %State{} = state) do
    :ok = state.impl.write(message, state.resource)

    execute_telemetry(:write, message, nil, state)
    sleep(state.opts)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:reset, opts}, %State{impl: impl, resource: resource}) do
    :ok = impl.terminate(:normal, resource)
    {:noreply, init_state(opts)}
  end

  @spec start_link(opts()) :: GenServer.on_start()
  def start_link(opts) do
    name = opts[:name]
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  defp execute_telemetry(event, query, answer, state) do
    :telemetry.execute(
      [:lab_live, :instrument, event],
      %{query: query, answer: answer, state: state}
    )
  end

  defp sleep(opts) do
    with sleep_time <- Keyword.get(opts, :sleep_after, 0),
         true <- sleep_time > 0 do
      Process.sleep(sleep_time)
    end
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
end
