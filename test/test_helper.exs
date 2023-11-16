ExUnit.start()

defmodule LabLive.Connection.Method.Fallback do
  @behaviour LabLive.Connection.Method
  def init(_opts), do: {:ok, nil}
  def terminate(:normal, nil), do: :ok
  def after_reply(_info, _resource), do: raise("please define mox expectation for after_reply/2")
  def read(_message, _resource), do: raise("please define mox expectation for read/2")
  def write(_message, _resource), do: raise("please define mox expectation for write/2")
end

Mox.defmock(LabLive.Connection.Method.Mock, for: LabLive.Connection.Method)
Application.put_env(:lab_live, :inst_type, LabLive.Connection.Method.Mock)
