# defmodule Test.Support.Model do
#   alias Test.Support.Format

#   defp query_joiner() do
#     [",", ":", " ", "/", ";"] |> Enum.map(&constant(&1))
#   end

#   defp termination() do
#     ["\r", "\n", "\r\n"] |> Enum.map(&constant(&1))
#   end

#   def model_stream(excluded \\ ["{", "}"]) do
#     bind(termination(), fn input_term ->
#       bind(termination(), fn output_term ->
#         bind()
#       end)
#     end)
#   end
# end
