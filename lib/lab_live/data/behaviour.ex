defmodule LabLive.Data.Behaviour do
  @type data() :: any()

  @callback new(any()) :: data()
  @callback value(data()) :: any()
  @callback update(data(), any()) :: data()
  @callback to_string(data()) :: String.t()
end
