defmodule FormatTest do
  use ExUnit.Case
  alias Labex.Utils.Format

  doctest Format

  test "format query" do
    query = "SET::VAL ~s,~p,~.2f"
    param_list = ["one", 2, 3.4]

    assert Format.format_query(query, param_list) == "SET::VAL one,2,3.40"
  end

  test "parse answer" do
    answer = "one,2,3.40"
    format = "~s,~n,~f"

    assert Format.parse_answer(answer, format) == ["one", 2, 3.4]
  end
end
