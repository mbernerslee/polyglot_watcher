defmodule PolyglotWatcher.UserInput do
  alias PolyglotWatcher.Elixir, as: ElixirLang

  @languages [ElixirLang]

  @startup_actions [
    {:run_sys_cmd, "tput", ["reset"]},
    {:puts,
     [
       {:white, "type "},
       {:cyan, "help"},
       {:white,
        " into this terminal to see a list of options and how to change watcher modes as I run"}
     ]}
  ]

  def usage(languages \\ @languages) do
    [
      {:white, "Usage\n\n"},
      {:yellow, "# General\n"},
      {:white, "  • "},
      {:cyan, "c"},
      {:white, "  clears the screen\n"},
      {:white, "  • "},
      {:cyan, "any unrecognised input"},
      {:white, "  prints this message"},
      {:white, "\n\n"}
    ] ++
      Enum.flat_map(languages, fn language -> Module.concat(language, UserInput).usage() end)
  end

  defp bad_cli_args_actions(command_line_args, languages) do
    messages =
      Enum.flat_map(languages, fn language -> Module.concat(language, UserInput).usage() end) ++
        [
          {:white, "\n"},
          {:red, "I didn't understand the command line arguments '#{command_line_args}'\n"},
          {:red, "The supported arguments are listed above\n\n"}
        ]

    [{:run_sys_cmd, "tput", ["reset"]}, {:puts, messages}]
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

  def startup(command_line_args, server_state, languages \\ @languages)

  def startup([], server_state, languages) do
    server_state = add_language_starting_states(server_state, languages)
    actions = prepend_startup_actions([{:puts, "Watching in default mode..."}])

    {:ok, {actions, server_state}}
  end

  def startup(command_line_args, server_state, languages) do
    server_state = add_language_starting_states(server_state, languages)

    {actions, server_state} =
      command_line_args
      |> Enum.join(" ")
      |> determine_actions(server_state, languages)

    if {actions, server_state} == unrecognised(server_state, languages) do
      {:error, {bad_cli_args_actions(command_line_args, languages), server_state}}
    else
      {:ok, {prepend_startup_actions(actions), server_state}}
    end
  end

  def determine_actions(user_input, server_state, languages \\ @languages) do
    user_input = String.trim(user_input)
    determine_actions(languages, user_input, server_state, languages)
  end

  defp add_language_starting_states(server_state, []) do
    server_state
  end

  defp add_language_starting_states(server_state, [language | rest]) do
    {language_key, starting_state} = Module.concat(language, Language).starting_state

    server_state = Map.put(server_state, language_key, starting_state)
    add_language_starting_states(server_state, rest)
  end

  defp prepend_startup_actions(actions) when is_list(actions) do
    @startup_actions ++ actions
  end

  defp prepend_startup_actions(%{run: run} = actions) do
    %{actions | run: @startup_actions ++ run}
  end

  defp determine_actions([], user_input, server_state, all_languages) do
    case language_agnostic_actions(user_input, server_state) do
      {:ok, {actions, server_state}} ->
        {actions, server_state}

      :error ->
        unrecognised(server_state, all_languages)
    end
  end

  defp determine_actions([language | rest], user_input, server_state, all_languages) do
    module = Module.concat(language, UserInput)

    case module.determine_actions(user_input, server_state) do
      {:ok, {actions, server_state}} -> {actions, server_state}
      :error -> determine_actions(rest, user_input, server_state, all_languages)
    end
  end

  defp unrecognised(server_state, languages) do
    {[{:puts, usage(languages)}], server_state}
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
