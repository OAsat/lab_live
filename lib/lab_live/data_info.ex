defmodule LabLive.DataInfo do
  @type t() :: %__MODULE__{
          label: String.t(),
          visible?: boolean()
        }

  defstruct label: "", visible?: true
end
