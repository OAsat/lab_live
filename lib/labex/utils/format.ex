defmodule Labex.Utils.Format do
  def format_query(query, param_list) do
    query
    |> :io_lib.format(param_list)
    |> :erlang.iolist_to_binary()
  end

  def parse_answer(answer, format) do
    ans_split = String.split(answer, ",")
    fmt_split = String.split(format, ",")

    Enum.zip([ans_split, fmt_split])
    |> Enum.map(fn {ans, fmt} ->
      case fmt do
        "~s" -> ans
        "~f" -> String.to_float(ans)
        "~n" -> String.to_integer(ans)
      end
    end)
  end
end
