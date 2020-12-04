defmodule PolyglotWatcher.Elixir.UserInput do
  alias PolyglotWatcher.Elixir.{Actions, Language, FixAllMode}
  # TODO make this use a behavior
  @prefix "ex"

  def prefix, do: @prefix

  # TODO move tests for this guy to here
  def determine(user_input, server_state) do
    case String.split(user_input, @prefix) do
      ["", suffix] -> suffix |> String.trim() |> do_determine(server_state)
      _ -> :error
    end
  end

  defp do_determine(suffix, server_state) do
    case suffix do
      "f" ->
        {:ok, fixed_previous_mode(server_state)}

      "d" ->
        {:ok, default_mode(server_state)}

      "a" ->
        {:ok, mix_test(server_state)}

      "fa" ->
        {:ok, FixAllMode.enter(server_state)}

      _ ->
        :error
    end
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
