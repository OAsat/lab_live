defmodule Lakeshore350 do
  @model %LabLive.Model{
    name: "LakeShore 350",
    character: %{
      input_term: "\n",
      output_term: "\r\n",
      joiner: ";"
    },
    query: %{
      setp?: %{
        input: "SETP? {{channel}}",
        output: "{{kelvin:float}}"
      },
      setp: %{
        input: "SETP {{channel}},{{kelvin}}"
      },
      range?: %{
        input: "RANGE? {{channel}}",
        output: "{{level:int}}"
      },
      range: %{
        input: "RANGE {{channel}},{{level}}"
      },
      ramp?: %{
        input: "RAMP? {{channel}}",
        output: "{{onoff:int}},{{kpermin:float}}"
      },
      ramp: %{
        input: "RAMP {{channel}},{{binary}},{{kpermin}}"
      },
      temp?: %{
        input: "KRDG? {{channel}}",
        output: "{{kelvin:float}}"
      },
      sensor?: %{
        input: "SRDG? {{channel}}",
        output: "{{ohm:float}}"
      },
      heater?: %{
        input: "HTR? {{channel}}",
        output: "{{percentage:float}}"
      },
      pid?: %{
        input: "PID? {{channel}}",
        output: "{{p:float}},{{i:float}},{{d:float}}"
      },
      pid: %{
        input: "PID {{channel}},{{p}},{{i}},{{d}}"
      }
    }
  }

  def model(), do: @model
end
