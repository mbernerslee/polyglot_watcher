defmodule PolyglotWatcher.UserInput do
  alias PolyglotWatcher.Elixir.UserInputParser, as: ElixirUserInputParser

  @languages [ElixirUserInputParser]

  def usage(languages \\ @languages) do
    prefix = """
    Usage

    General
      c - clears the screen

    """

    suffix = "\nAny unrecocogised input - prints this message\n"

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

  def determine_startup_actions(command_line_args, server_state, languages \\ @languages)

  def determine_startup_actions([], server_state, _languages) do
    {:ok, {[], server_state}}
  end

  # TODO add the concept of startup CLI options to the language module.
  # Extend the Language behavior for this & add a function analagous to usage for startup msg, that cycles through the languages
  # and call that instead of fudging it  like this.
  # TODO have clearly different output for startup vs usage. rename usage to help or... modes or something
  # TODO add a red msg at the bottom of the usage output if unexpected stuff is read
  def determine_startup_actions(command_line_args, server_state, languages) do
    {actions, updated_server_state} =
      command_line_args
      |> Enum.join(" ")
      |> determine_actions(server_state, languages)

    if {actions, updated_server_state} == unrecognised(server_state, languages) do
      {:error,
       {[
          {:puts, usage(languages)},
          {:puts, :red, "I didn't understand the command line argumenents you gave me\nExiting"}
        ], updated_server_state}}
    else
      {:ok, {actions, updated_server_state}}
    end
  end

  def determine_actions(user_input, server_state, languages \\ @languages) do
    user_input = String.trim(user_input)
    determine_actions(languages, user_input, server_state, languages)
  end

  defp determine_actions([], user_input, server_state, all_languages) do
    case language_agnostic_actions(user_input, server_state) do
      {:ok, {actions, server_state}} ->
        {actions, server_state}

      :error ->
        unrecognised(server_state, all_languages)
    end
  end

  defp unrecognised(server_state, languages \\ @languages) do
    {[{:puts, usage(languages)}], server_state}
  end

  defp determine_actions([language | rest], user_input, server_state, all_languages) do
    case language.determine_actions(user_input, server_state) do
      {:ok, {actions, server_state}} -> {actions, server_state}
      :error -> determine_actions(rest, user_input, server_state, all_languages)
    end
  end

  defp language_agnostic_actions do
    %{
      "c" => fn server_state -> {[{:run_sys_cmd, "tput", ["reset"]}], server_state} end
    }
  end

  defp language_agnostic_actions(user_input, server_state) do
    case language_agnostic_actions()[user_input] do
      nil -> :error
      fun -> {:ok, fun.(server_state)}
    end
  end
end
