defmodule LabLive.Variable do
  use GenServer

  def start_link({name, opts}) do
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def start_link(name) when is_atom(name) do
    start_link({name, []})
  end

  @impl GenServer
  def init(opts) do
    init = Keyword.get(opts, :init, nil)
    max_size = Keyword.get(opts, :max_size, 1)

    if max_size < 1 do
      raise "max_size must be at least 1."
    end

    {q, q_stat} = init_queue(init)

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
  def handle_call(:as_list, _from, state = {q, _, _}) do
    {:reply, :queue.to_list(q), state}
  end

  @impl GenServer
  def handle_cast(:refresh, {_q, max_size, _q_stat}) do
    {q, q_stat} = init_queue(nil)
    {:noreply, {q, max_size, q_stat}}
  end

  defp init_queue(nil) do
    {:queue.new(), %{size: 0, sum: 0, square_sum: 0}}
  end

  defp init_queue(value) do
    q = :queue.in(value, :queue.new())

    if is_number(value) do
      {q, %{size: 1, sum: value, square_sum: value * value}}
    else
      {q, %{size: 1}}
    end
  end

  defp append_to_q_stat(q_stat, value) do
    if is_number(value) do
      %{
        size: q_stat.size + 1,
        sum: q_stat.sum + value,
        square_sum: q_stat.square_sum + value * value
      }
    else
      %{
        size: q_stat.size + 1
      }
    end
  end

  defp remove_from_q_stat(q_stat, value) do
    if is_number(value) do
      %{
        size: q_stat.size - 1,
        sum: q_stat.sum - value,
        square_sum: q_stat.square_sum - value * value
      }
    else
      %{
        size: q_stat.size - 1
      }
    end
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

  def as_list(pid) do
    GenServer.call(pid, :as_list)
  end
end
