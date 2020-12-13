defmodule PolyglotWatcher.ExampleLanguages.Pear.UserInputParser do
  alias PolyglotWatcher.UserInputParser

  @behaviour UserInputParser

  @impl UserInputParser
  def prefix, do: "pear"

  @impl UserInputParser
  def usage, do: [{:green, "how to use pear"}]

  @impl UserInputParser
  def determine_actions(user_input, server_state) do
    user_input
    |> String.split(prefix(), trim: true)
    |> Enum.map(&String.trim/1)
    |> case do
      ["pick"] -> {:ok, {[{:puts, "pick"}], Map.put(server_state, :pick, true)}}
      ["eat"] -> {:ok, {[{:puts, "eat"}], Map.put(server_state, :eat, true)}}
      ["peel"] -> {:ok, {%{run: [{:puts, "peel"}]}, Map.put(server_state, :peel, true)}}
      _ -> :error
    end
  end
end
