defprotocol LabLive.Data.Protocol do
  @fallback_to_any true
  def value(data)
  def update(data, new)
end

defimpl LabLive.Data.Protocol, for: Any do
  def value(data), do: data
  def update(_data, new), do: new
end

defimpl LabLive.Data.Protocol,
  for: [
    LabLive.Data.Cache,
    LabLive.Data.Csv,
    LabLive.Data.Iterator,
    LabLive.Data.Timer,
    LabLive.Data.Loop
  ] do
  def value(%struct{} = data), do: struct.value(data)
  def update(%struct{} = data, new), do: struct.update(data, new)
end

defimpl String.Chars,
  for: [
    LabLive.Data.Cache,
    LabLive.Data.Csv,
    LabLive.Data.Iterator,
    LabLive.Data.Timer,
    LabLive.Data.Loop
  ] do
  def to_string(%struct{} = data), do: struct.to_string(data)
end
