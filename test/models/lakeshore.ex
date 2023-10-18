defmodule LabexInstruments.Lakeshore do
  alias Labex.Model
  use Model

  def_read(:kelvin, "KRDG? {channel}", "{temperature:float}")
  def_read(:sensor, "SRDG? {channel}", "{resistance:float}")

  def_write(:setpoint, "SETP {channel}, {temperature:float}")
  def_read(:setpoint, "SETP? {channel}")
end
