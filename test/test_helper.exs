ExUnit.start()

Code.require_file("test/support/tcp_server.ex")
Code.require_file("test/support/lakeshore350.ex")

defmodule LabLive.Instrument.FallbackImpl do
  @behaviour LabLive.Instrument.Impl
  def init(_opts), do: {:ok, nil}
  def terminate(:normal, nil), do: :ok
  def after_reply(_info, _resource), do: raise("please define mox expectation for after_reply/2")
  def read(_message, _resource), do: raise("please define mox expectation for read/2")
  def write(_message, _resource), do: raise("please define mox expectation for write/2")
end

Mox.defmock(LabLive.Instrument.ImplMock, for: LabLive.Instrument.Impl)
Application.put_env(:lab_live, :inst_type, LabLive.Instrument.ImplMock)
