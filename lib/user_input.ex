defmodule PolyglotWatcher.UserInput do
  alias PolyglotWatcher.Echo

  @usage """
  Usage

  Elixir
    ex f                  -  fixed mode: only run the most recently run test that failed (when elixir files are saved)
    ex /path/to/test.exs  -  fixed mode: only run that test (when elixir files are saved)
    ex d                  -  default mode: return to default elixir settings
  """

  def determine_actions(user_input, server_state) do
    case String.trim(user_input) do
      "ex f" ->
        fixed_previous_mode(server_state)

      "ex d" ->
        default_mode(server_state)

      _ ->
        {[{:run_sys_cmd, "echo", Echo.pink(@usage)}], server_state}
    end
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
           {:run_sys_cmd, "echo", Echo.pink("Retern to default mode by entering 'ex d'")},
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
