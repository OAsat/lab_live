defmodule LabLive.Instrument do
  alias LabLive.Model
  defstruct name: nil, type: nil, model: %Model{}, info: %{}
end
