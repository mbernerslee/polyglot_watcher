defmodule PolyglotWatcher.UserInput do
  alias PolyglotWatcher.Elixir.UserInputParser, as: ElixirUserInputParser

  @languages [ElixirUserInputParser]

  def usage(languages \\ @languages) do
    prefix = "Usage\n\n"
    suffix = "\nAny unrecocogised input - prints this message"

    language_usages =
      languages
      |> Enum.map(fn language -> language.usage() end)
      |> Enum.join("\n\n")

    prefix <> language_usages <> suffix
  end

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
    determine_actions(languages, user_input, server_state, languages)
  end

  defp determine_actions([], _user_input, server_state, all_languages) do
    {[{:puts, usage(all_languages)}], server_state}
  end

  defp determine_actions([language | rest], user_input, server_state, all_languages) do
    case language.determine_actions(user_input, server_state) do
      {:ok, {actions, server_state}} -> {actions, server_state}
      :error -> determine_actions(rest, user_input, server_state, all_languages)
    end
  end
end
