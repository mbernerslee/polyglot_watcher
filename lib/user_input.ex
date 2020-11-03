defmodule PolyglotWatcher.UserInput do
  alias PolyglotWatcher.Echo

  @usage """
  Usage

  Elixir
    ex f                  -  fixed mode: only run the most recently run test that failed (when elixir files are saved)
    ex /path/to/test.exs  -  fixed mode: only run that test (when elixir files are saved)
    ex d                  -  default mode: return to default elixir settings
    ex a                  -  run 'mix test' (run all tests)
  """

  def determine_actions(user_input, server_state) do
    case String.trim(user_input) do
      "ex f" ->
        fixed_previous_mode(server_state)

      "ex d" ->
        default_mode(server_state)

      "ex a" ->
        mix_test(server_state)

      other ->
        maybe_enter_fixed_file_mode(other, server_state)
    end
  end

  def mix_test(server_state) do
    {[
       {:run_sys_cmd, "echo", Echo.pink("Running 'mix test'")},
       :mix_test
     ], server_state}
  end

  def maybe_enter_fixed_file_mode(user_input, server_state) do
    case String.split(user_input, "ex ") do
      ["", possible_file_path] ->
        if legit_looking_test_file?(possible_file_path) do
          {[
             {:run_sys_cmd, "echo", Echo.pink("Switching to fixed file mode")},
             {:run_sys_cmd, "echo",
              Echo.pink("I'll only run 'mix test #{possible_file_path}' unless told otherwise")},
             {:run_sys_cmd, "echo", Echo.pink("Return to default mode by entering 'ex d'")},
             {:mix_test, possible_file_path}
           ], put_in(server_state, [:elixir, :mode], {:fixed_file, possible_file_path})}
        else
          echo_usage(server_state)
        end

      _ ->
        echo_usage(server_state)
    end
  end

  defp echo_usage(server_state) do
    {[{:run_sys_cmd, "echo", Echo.pink(@usage)}], server_state}
  end

  defp legit_looking_test_file?(file_path) do
    Regex.match?(~r|^test/.+_test.exs.*|, file_path)
  end

  defp default_mode(server_state) do
    {[{:run_sys_cmd, "echo", Echo.pink("Switching back to default mode")}],
     put_in(server_state, [:elixir, :mode], :default)}
  end

  defp fixed_previous_mode(server_state) do
    case server_state[:elixir][:failures] do
      [most_recent | _] ->
        {[
           {:run_sys_cmd, "echo", Echo.pink("Switching to fixed mode")},
           {:run_sys_cmd, "echo",
            Echo.pink("Will only run 'mix test #{most_recent}' unless told otherwise...")},
           {:run_sys_cmd, "echo", Echo.pink("Return to default mode by entering 'ex d'")},
           {:mix_test, most_recent}
         ], put_in(server_state, [:elixir, :mode], :fixed_previous)}

      _ ->
        {[
           {:run_sys_cmd, "echo",
            Echo.red("Cannot switch to fixed mode because my memory of failing tests is empty")},
           {:run_sys_cmd, "echo", Echo.red("so I don't know which test you want me to run...")}
         ], server_state}
    end
  end
end
