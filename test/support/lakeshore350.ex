defmodule Lakeshore350 do
  use LabLive.Instrument.Model
  def read_termination, do: "\r\n"

  def read_format(:setp), do: {"SETP? {{channel}}", "{{kelvin:float}}"}
  def read_format(:range), do: {"RANGE? {{channel}}", "{{level:int}}"}
  def read_format(:ramp), do: {"RAMP? {{channel}}", "{{onoff:int}},{{kpermin:float}}"}
  def read_format(:kelvin), do: {"KRDG? {{channel}}", "{{kelvin:float}}"}
  def read_format(:sensor), do: {"SRDG? {{channel}}", "{{ohm:float}}"}
  def read_format(:heater), do: {"HTR? {{channel}}", "{{percentage:float}}"}

  def write_format(:setp), do: "SETP {{channel}},{{kelvin}}"
  def write_format(:range), do: "RANGE {{channel}},{{level}}"
  def write_format(:ramp), do: "RAMP {{channel}},{{binary}},{{kpermin}}"

  def dummy() do
    %{
      "SETP? 2\n" => "1.0\r\n",
      "RANGE? 2\n" => "2\r\n",
      "RAMP? 2\n" => "1,0.2\n",
      "KRDG? A\n" => "50.0\r\n",
      "SRDG? A\n" => "1000.0\r\n",
      "HTR? 2\n" => "11.1\r\n",
      "SRDG? A;HTR? 2\n" => "1200.0;56.7\r\n",
      "SETP 2,1.0\n" => nil,
      "RANGE 2,2\n" => nil,
      "RAMP 2,1,0.2\n" => nil
    }
  end
end
