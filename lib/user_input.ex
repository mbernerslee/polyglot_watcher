defmodule PolyglotWatcher.UserInput do
  alias PolyglotWatcher.Elixir.UserInput, as: ElixirUserInput
  alias PolyglotWatcher.Elixir.Actions, as: ElixirActions

  # TODO move language usage stuff to language specific module
  @usage """
  Usage

  Elixir
    ex f                  -  fixed mode: only run the most recently run test that failed (when elixir files are saved)
    ex /path/to/test.exs  -  fixed mode: only run that test (when elixir files are saved)
    ex fa                 -  fix all mode
    ex d                  -  default mode: return to default elixir settings
    ex a                  -  run 'mix test' (run all tests)
  """

  @languages [
    ElixirUserInput
  ]

  # TODO have a "ex ra" mode that runes 'mix test' given any elixir file change
  # TODO make it clear that ex a runs all the tests as a one off
  # TODO move the language specific parsing test elsewhere? Have a token test that language is wired in?
  def determine_actions(user_input, server_state) do
    user_input = String.trim(user_input)
    find_language_actions(@languages, user_input, server_state)
  end

  defp find_language_actions([], user_input, server_state) do
    maybe_enter_fixed_file_mode(user_input, server_state)
  end

  defp find_language_actions([language | rest], user_input, server_state) do
    case language.determine(user_input, server_state) do
      {:ok, {actions, server_state}} -> {actions, server_state}
      :error -> find_language_actions(rest, user_input, server_state)
    end
  end

  # TODO move this to an elixir specific module somehow?
  defp maybe_enter_fixed_file_mode(user_input, server_state) do
    case String.split(user_input, "ex ") do
      ["", possible_file_path] ->
        if legit_looking_test_file?(possible_file_path) do
          {[
             {:puts, "Switching to fixed file mode"},
             {:puts, "I'll only run 'mix test #{possible_file_path}' unless told otherwise"},
             {:puts, "Return to default mode by entering 'ex d'"},
             ElixirActions.mix_test(possible_file_path)
           ], put_in(server_state, [:elixir, :mode], {:fixed_file, possible_file_path})}
        else
          echo_usage(server_state)
        end

      _ ->
        echo_usage(server_state)
    end
  end

  defp echo_usage(server_state) do
    {[{:puts, @usage}], server_state}
  end

  defp legit_looking_test_file?(file_path) do
    Regex.match?(~r|^test/.+_test.exs.*|, file_path)
  end
end
