defmodule PolyglotWatcher.Elixir.UserInputParser do
  alias PolyglotWatcher.Elixir.{Actions, Language, FixAllMode}
  alias PolyglotWatcher.UserInput
  alias PolyglotWatcher.UserInputParser

  @behaviour UserInputParser

  @prefix "ex"

  @impl UserInputParser
  def prefix, do: @prefix

  @impl UserInputParser
  def usage do
    """
    Elixir
      #{@prefix} f                  -  fixed mode: only run the most recently run test that failed (when elixir files are saved)
      #{@prefix} /path/to/test.exs  -  fixed mode: only run that test (when elixir files are saved)
      #{@prefix} fa                 -  fix all mode
      #{@prefix} d                  -  default mode: return to default elixir settings
      #{@prefix} a                  -  run 'mix test' (run all tests)
    """
  end

  @impl UserInputParser
  def determine_actions(user_input, server_state) do
    user_input
    |> UserInput.parse(@prefix)
    |> map_input_to_actions(server_state)
    |> fallback(server_state)
  end

  defp fallback(:error, _server_state) do
    :error
  end

  defp fallback({:ok, {actions, server_state}}, _server_state) do
    {:ok, {actions, server_state}}
  end

  defp fallback({:error, possible_file_path}, server_state) do
    if legit_looking_test_file?(possible_file_path) do
      {:ok,
       {[
          {:puts, "Switching to fixed file mode"},
          {:puts, "I'll only run 'mix test #{possible_file_path}' unless told otherwise"},
          {:puts, "Return to default mode by entering 'ex d'"},
          Actions.mix_test(possible_file_path)
        ], put_in(server_state, [:elixir, :mode], {:fixed_file, possible_file_path})}}
    else
      :error
    end
  end

  defp map_input_to_actions({:ok, suffix}, server_state) do
    case Map.get(input_to_actions_mapping(), suffix) do
      nil -> {:error, suffix}
      actions_fun -> {:ok, actions_fun.(server_state)}
    end
  end

  defp map_input_to_actions(error, _server_state) do
    error
  end

  defp input_to_actions_mapping do
    %{
      "f" => &fixed_previous_mode/1,
      "d" => &default_mode/1,
      "a" => &mix_test/1,
      "fa" => &FixAllMode.enter/1
    }
  end

  defp legit_looking_test_file?(file_path) do
    Regex.match?(~r|^test/.+_test.exs.*|, file_path)
  end

  defp fixed_previous_mode(server_state) do
    case server_state[:elixir][:failures] do
      [most_recent | _] ->
        {[
           {:puts, "Switching to fixed mode"},
           {:puts, "Will only run 'mix test #{most_recent}' unless told otherwise..."},
           {:puts, "Return to default mode by entering 'ex d'"},
           Actions.mix_test(most_recent)
         ], Language.set_mode(server_state, :fixed_previous)}

      _ ->
        {[
           {:puts, :red,
            "Cannot switch to fixed mode because my memory of failing tests is empty"},
           {:puts, :red, "so I don't know which test you want me to run..."}
         ], server_state}
    end
  end

  defp default_mode(server_state) do
    {[{:puts, "Switching back to default mode"}], Language.set_mode(server_state, :default)}
  end

  defp mix_test(server_state) do
    {[{:puts, "Running 'mix test'"}, Actions.mix_test()], server_state}
  end
end
