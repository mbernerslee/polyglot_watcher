defmodule PolyglotWatcher.Elixir.UserInput do
  alias PolyglotWatcher.Elixir.Actions
  alias PolyglotWatcher.Elixir.Language
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
        {:ok, fix_all_mode(server_state)}

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

  defp fix_all_mode(server_state) do
    {[
       {:puts, "Switching to fix all mode"},
       {:puts, "It'll run: "},
       {:puts, "1) 'mix test' to see how bad it is.."},
       {:puts,
        "2) 'mix test /path/to/specific/failure_test.exs:23' ... some arbirarily chosen broken test...until it pases"},
       {:puts,
        "3) 'mix test /path/to/specific/failure_test.exs' ... to see if there're still some broken tests. if yes goto 2)"},
       {:puts,
        "4) 'mix test --failed' ... to see if there're still some broken tests. if yes goto 2)"},
       {:puts,
        "5) 'mix test --failed --max-failures 1' ... to find the next failing test. if there is one goto 2)"},
       {:puts,
        "6) 'mix test' ... if this passes we're good! (otherwise go back to 2), *waw waw*)"},
       Actions.mix_test()
     ], Language.set_mode(server_state, {:fix_all, :run_single})}
  end
end
