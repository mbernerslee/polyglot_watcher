defmodule PolyglotWatcher.UserInput do
  alias PolyglotWatcher.Elixir.UserInputParser, as: ElixirUserInputParser

  @usage """
  Usage

  Elixir
    ex f                  -  fixed mode: only run the most recently run test that failed (when elixir files are saved)
    ex /path/to/test.exs  -  fixed mode: only run that test (when elixir files are saved)
    ex fa                 -  fix all mode
    ex d                  -  default mode: return to default elixir settings
    ex a                  -  run 'mix test' (run all tests)
  """

  @languages [ElixirUserInputParser]

  def usage, do: @usage

  def parse(user_input, prefix) do
    user_input
    |> String.split("#{prefix} ", parts: 2)
    |> Enum.map(&String.trim/1)
    |> case do
      ["", result] -> {:ok, result}
      _ -> :error
    end
  end

  def determine_actions(user_input, server_state, languages \\ @languages) do
    user_input = String.trim(user_input)
    determine(languages, user_input, server_state)
  end

  defp determine([], _user_input, server_state) do
    {[{:puts, @usage}], server_state}
  end

  defp determine([language | rest], user_input, server_state) do
    case language.determine_actions(user_input, server_state) do
      {:ok, {actions, server_state}} -> {actions, server_state}
      :error -> determine(rest, user_input, server_state)
    end
  end
end
