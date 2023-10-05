defmodule LabexInstruments.Lakeshore do
  alias Labex.Instrument.Model
  use Model

  def_read(:kelvin, "KRDG? {s:channel}", "{f:temperature}")
  def_read(:sensor, "SRDG? {s:channel}", "{f:resistance}")

  def_write(:setpoint, "SETP {s:channel}, {f:temperature}")
  def_read(:setpoint, "SETP? {s:channel}")
end
