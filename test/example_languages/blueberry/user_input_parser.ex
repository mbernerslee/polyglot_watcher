defmodule PolyglotWatcher.ExampleLanguages.Blueberry.UserInputParser do
  alias PolyglotWatcher.UserInputParser

  @behaviour UserInputParser

  @impl UserInputParser
  def prefix, do: "blueb"

  @impl UserInputParser
  def usage, do: [{:red, "how to use blueb"}]

  @impl UserInputParser
  def determine_actions(user_input, server_state) do
    user_input
    |> String.split(prefix(), trim: true)
    |> Enum.map(&String.trim/1)
    |> case do
      ["harvest"] -> {:ok, {[{:puts, "harvest"}], Map.put(server_state, :harvest, true)}}
      ["nom"] -> {:ok, {[{:puts, "nom"}], Map.put(server_state, :nom, true)}}
      _ -> :error
    end
  end
end
