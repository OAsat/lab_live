ExUnit.start()

Code.require_file("test/support/tcp_server.ex")
Code.require_file("test/support/lakeshore350.ex")

Mox.defmock(LabLive.Instrument.PortMock, for: LabLive.Instrument.Impl)
Application.put_env(:lab_live, :inst_type, LabLive.Instrument.PortMock)
