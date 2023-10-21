defmodule LabLive.Variable do
  use GenServer

  def start_link({name, opts}) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    init = Keyword.get(opts, :init, nil)
    max_size = Keyword.get(opts, :max_size, 1)

    if max_size < 1 do
      raise "max_size must be at least 1."
    end

    q = init_queue(init)
    q_stat = new_q_stat(q)

    {:ok, {q, max_size, q_stat}}
  end

  @impl GenServer
  def handle_call({:append, value}, _from, {q, max_size, q_stat}) do
    q_new = :queue.in(value, q)
    q_stat_new = append_to_q_stat(q_stat, value)

    if q_stat_new.size > max_size do
      {{:value, removed}, q_new} = :queue.out(q_new)
      q_stat_new = remove_from_q_stat(q_stat_new, removed)
      {:reply, removed, {q_new, max_size, q_stat_new}}
    else
      {:reply, :ok, {q_new, max_size, q_stat_new}}
    end
  end

  @impl GenServer
  def handle_call(:latest, _from, state = {q, _max_size, _q_stat}) do
    case :queue.peek_r(q) do
      {:value, value} -> {:reply, value, state}
      :empty -> {:reply, :empty, state}
    end
  end

  @impl GenServer
  def handle_call(:stats, _from, state = {_q, _max_size, q_stat}) do
    {:reply, q_stat, state}
  end

  @impl GenServer
  def handle_cast(:refresh, {_q, max_size, _q_stat}) do
    q = init_queue(nil)
    {:noreply, {q, max_size, new_q_stat(q)}}
  end

  defp init_queue(nil) do
    :queue.new()
  end

  defp init_queue(value) do
    :queue.in(value, :queue.new())
  end

  defp new_q_stat(q) do
    list = :queue.to_list(q)

    %{
      size: length(list),
      sum: Enum.sum(list),
      square_sum: Enum.reduce(list, 0, fn x, acc -> acc + x * x end)
    }
  end

  defp append_to_q_stat(q_stat, value) do
    %{
      size: q_stat.size + 1,
      sum: q_stat.sum + value,
      square_sum: q_stat.square_sum + value * value
    }
  end

  defp remove_from_q_stat(q_stat, value) do
    %{
      size: q_stat.size - 1,
      sum: q_stat.sum - value,
      square_sum: q_stat.square_sum - value * value
    }
  end

  def append(pid, value) do
    GenServer.call(pid, {:append, value})
  end

  def latest(pid) do
    GenServer.call(pid, :latest)
  end

  def stats(pid) do
    GenServer.call(pid, :stats)
  end

  def refresh(pid) do
    GenServer.cast(pid, :refresh)
  end
end
