defmodule LabLive.Widget.InstrumentsSetupTest do
  use ExUnit.Case
  alias LabLive.Widget.InstrumentsSetup
  alias LabLive.Model
  doctest InstrumentsSetup

  describe "convert_attrs_specs/1" do
    setup do
      empty_src = %{
        "name" => "inst",
        "sleep_after_reply" => "0",
        "model" => "",
        "selected_type" => "Dummy",
        "dummy" => %{"if_random" => "False"},
        "pyvisa" => %{"address" => ""},
        "tcp" => %{"address" => "", "port" => ""}
      }

      empty_exp = %{
        name: :inst,
        sleep_after_reply: 0,
        model: nil,
        selected_type: :dummy,
        dummy: %{random: false, model: nil},
        pyvisa: %{address: ""},
        tcp: %{address: nil, port: nil}
      }

      [empty_src: empty_src, empty_exp: empty_exp]
    end

    test "converts empty attrs", %{empty_src: src, empty_exp: exp} do
      assert [inst: exp] == InstrumentsSetup.convert_attrs_specs([src])
    end

    test "converts model", %{empty_src: empty_src, empty_exp: empty_exp} do
      src = %{empty_src | "model" => "%{}"}
      exp = %{empty_exp | model: %Model{}, dummy: %{random: false, model: %Model{}}}
      assert [inst: exp] == InstrumentsSetup.convert_attrs_specs([src])
    end

    test "converts sleep_after_reply=''", %{empty_src: empty_src, empty_exp: empty_exp} do
      src = %{empty_src | "sleep_after_reply" => ""}
      exp = %{empty_exp | sleep_after_reply: nil}
      assert [inst: exp] == InstrumentsSetup.convert_attrs_specs([src])
    end

    test "converts sleep_after_reply", %{empty_src: empty_src, empty_exp: empty_exp} do
      src = %{empty_src | "sleep_after_reply" => "100"}
      exp = %{empty_exp | sleep_after_reply: 100}
      assert [inst: exp] == InstrumentsSetup.convert_attrs_specs([src])
    end

    test "converts selected_type", %{empty_src: empty_src, empty_exp: empty_exp} do
      src = %{empty_src | "selected_type" => "PyVISA"}
      exp = %{empty_exp | selected_type: :pyvisa}
      assert [inst: exp] == InstrumentsSetup.convert_attrs_specs([src])

      src = %{empty_src | "selected_type" => "TCP/IP"}
      exp = %{empty_exp | selected_type: :tcp}
      assert [inst: exp] == InstrumentsSetup.convert_attrs_specs([src])
    end

    test "converts dummy spec", %{empty_src: empty_src, empty_exp: empty_exp} do
      src = %{empty_src | "dummy" => %{"if_random" => "True"}}
      exp = %{empty_exp | dummy: %{random: true, model: nil}}
      assert [inst: exp] == InstrumentsSetup.convert_attrs_specs([src])
    end

    test "converts pyvisa spec", %{empty_src: empty_src, empty_exp: empty_exp} do
      src = %{empty_src | "pyvisa" => %{"address" => "gpib"}}
      exp = %{empty_exp | pyvisa: %{address: "gpib"}}
      assert [inst: exp] == InstrumentsSetup.convert_attrs_specs([src])
    end

    test "converts tcp spec", %{empty_src: empty_src, empty_exp: empty_exp} do
      src = %{empty_src | "tcp" => %{"port" => "1234", "address" => "123"}}
      exp = %{empty_exp | tcp: %{port: 1234, address: nil}}
      assert [inst: exp] == InstrumentsSetup.convert_attrs_specs([src])

      src = %{empty_src | "tcp" => %{"port" => "1234", "address" => "123.45"}}
      exp = %{empty_exp | tcp: %{port: 1234, address: nil}}
      assert [inst: exp] == InstrumentsSetup.convert_attrs_specs([src])

      src = %{empty_src | "tcp" => %{"port" => "1234", "address" => "123.45.6"}}
      exp = %{empty_exp | tcp: %{port: 1234, address: nil}}
      assert [inst: exp] == InstrumentsSetup.convert_attrs_specs([src])

      src = %{empty_src | "tcp" => %{"port" => "1234", "address" => "123.45.6.7"}}
      exp = %{empty_exp | tcp: %{port: 1234, address: [123, 45, 6, 7]}}
      assert [inst: exp] == InstrumentsSetup.convert_attrs_specs([src])
    end
  end
end
