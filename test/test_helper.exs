ExUnit.start()

defmodule LabLive.Connection.Method.Fallback do
  @behaviour LabLive.Connection.Method
  def init(_opts), do: {:ok, nil}
  def terminate(:normal, nil), do: :ok
  def read(_message, _resource), do: raise("please define mox expectation for read/2")
  def write(_message, _resource), do: raise("please define mox expectation for write/2")
end

Mox.defmock(LabLive.Connection.Method.Mock, for: LabLive.Connection.Method)
