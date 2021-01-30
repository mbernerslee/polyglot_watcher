defmodule PolyglotWatcher.Elixir.UserInput do
  alias PolyglotWatcher.Elixir.{Actions, Language, FixAllMode, Usage}
  alias PolyglotWatcher.UserInputBehaviour
  alias PolyglotWatcher.UserInput

  @behaviour UserInputBehaviour

  @prefix "ex"

  @impl UserInputBehaviour
  def prefix, do: @prefix

  @impl UserInputBehaviour
  defdelegate usage, to: Usage

  @impl UserInputBehaviour
  def determine_actions(user_input, server_state) do
    user_input
    |> UserInput.parse(@prefix)
    |> map_input_to_actions(server_state)
    |> fallback(server_state)
  end

  defp fallback(:error, _server_state) do
    :no_actions
  end

  defp fallback({:ok, {actions, server_state}}, _server_state) do
    {:ok, {actions, server_state}}
  end

  defp fallback({:error, possible_file_path}, server_state) do
    if legit_looking_test_file?(possible_file_path) do
      {:ok,
       {fixed_previous_mode_actions(possible_file_path),
        put_in(server_state, [:elixir, :mode], {:fixed_file, possible_file_path})}}
    else
      :no_actions
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

  defp fixed_previous_mode_actions(test_path) do
    [
      {:run_sys_cmd, "tput", ["reset"]},
      {:puts, "Switching to fixed mode"},
      {:puts, "I'll only run 'mix test #{test_path}' unless told otherwise"},
      {:puts, "Return to default mode by entering 'ex d'"},
      Actions.mix_test(test_path)
    ]
  end

  defp fixed_previous_mode(server_state) do
    case server_state[:elixir][:failures] do
      [most_recent | _] ->
        {fixed_previous_mode_actions(most_recent),
         Language.set_mode(server_state, :fixed_previous)}

      _ ->
        {[
           {:puts, :red,
            "Cannot switch to fixed mode because my memory of failing tests is empty"},
           {:puts, :red, "so I don't know which test you want me to run..."}
         ], server_state}
    end
  end

  defp default_mode(server_state) do
    {[
       {:run_sys_cmd, "tput", ["reset"]},
       {:puts, "Switching to default mode"}
     ], Language.set_mode(server_state, :default)}
  end

  defp mix_test(server_state) do
    {[{:puts, "Running 'mix test'"}, Actions.mix_test()], server_state}
  end
end
