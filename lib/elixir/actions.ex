defmodule PolyglotWatcher.Elixir.Actions do
  alias PolyglotWatcher.{CommonActions, Puts}
  alias PolyglotWatcher.Elixir.Language

  @success_exit_code 0

  def mix_test do
    {:module_action, __MODULE__, :mix_test}
  end

  def mix_test_quietly do
    {:module_action, __MODULE__, :mix_test_quietly}
  end

  def mix_test(test_path) do
    {:module_action, __MODULE__, {:mix_test, test_path}}
  end

  def mix_test_head_single do
    {:module_action, __MODULE__, :mix_test_head_single}
  end

  def mix_test_head_file_quietly do
    {:module_action, __MODULE__, :mix_test_head_file_quietly}
  end

  def mix_test_failed_one do
    {:module_action, __MODULE__, :mix_test_failed_one}
  end

  defp put_summary({:ok, summary}, @success_exit_code, previous_line) do
    Puts.on_previous_line(previous_line ++ [{:green, "✓ #{summary}"}])
  end

  defp put_summary({:ok, summary}, _, previous_line) do
    Puts.on_previous_line(previous_line ++ [{:red, "\u274C #{summary}"}])
  end

  defp put_summary({:error, error}, _, _) do
    IO.puts(error)
  end

  def run_action(:mix_test_quietly, server_state) do
    message = "Running 'mix test' "
    colour = :magenta
    current_line = [{colour, message}]
    Puts.on_new_line(message, colour)

    # {mix_test_output, exit_code} =
    #  CommonActions.spin_while(
    #    fn -> System.cmd("mix", ["test", "--color"], stderr_to_stdout: true) end,
    #    current_line
    #  )
    mix_test_output = "oops"
    exit_code = 1

    mix_test_output
    |> Language.mix_test_summary()
    |> put_summary(exit_code, current_line)

    {exit_code, Language.reset_mix_test_history(server_state, mix_test_output)}
  end

  def run_action({:mix_test, path}, server_state) do
    {mix_test_output, exit_code} =
      System.cmd("mix", ["test", path, "--color"], stderr_to_stdout: true)

    IO.puts(mix_test_output)
    {exit_code, Language.add_mix_test_history(server_state, mix_test_output)}
  end

  def run_action(:mix_test, server_state) do
    {mix_test_output, exit_code} = System.cmd("mix", ["test", "--color"], stderr_to_stdout: true)
    IO.puts(mix_test_output)
    {exit_code, Language.reset_mix_test_history(server_state, mix_test_output)}
  end

  def run_action(:mix_test_head_single, server_state) do
    case server_state.elixir.failures do
      [] ->
        Puts.on_new_line(
          "i expected there to be at least one failing test in my memory, but there were none",
          :red
        )

        {1, Language.set_mode(server_state, {:fix_all, :mix_test})}

      [failure | _rest] ->
        Puts.on_new_line("Running 'mix test #{failure}'...until it passes", :magenta)
        run_action({:mix_test, failure}, server_state)
    end
  end

  def run_action(:mix_test_head_file_quietly, server_state) do
    case server_state.elixir.failures do
      [] ->
        Puts.on_new_line(
          "i expected there to be at least one failing test in my memory, but there were none",
          :red
        )

        {1, Language.set_mode(server_state, {:fix_all, :mix_test})}

      [failure | _rest] ->
        file = trim_line_number(failure)

        message = "Running 'mix test #{file}'  "
        colour = :magenta
        current_line = [{colour, message}]
        Puts.on_new_line(message, :magenta)

        {mix_test_output, exit_code} =
          CommonActions.spin_while(
            fn ->
              System.cmd("mix", ["test", file, "--color"], stderr_to_stdout: true)
            end,
            current_line
          )

        mix_test_output
        |> Language.mix_test_summary()
        |> put_summary(exit_code, current_line)

        server_state =
          Language.update_mix_test_history_for_file(server_state, file, mix_test_output)

        {exit_code, server_state}
    end
  end

  def run_action(:mix_test_failed_one, server_state) do
    message = "Running 'mix test --failed --max-failures 1'    "
    colour = :magenta
    current_line = [{colour, message}]
    Puts.on_new_line(message, colour)

    {mix_test_output, exit_code} =
      CommonActions.spin_while(
        fn ->
          System.cmd("mix", ["test", "--color", "--failed", "--max-failures", "1"],
            stderr_to_stdout: true
          )
        end,
        current_line
      )

    mix_test_output
    |> Language.mix_test_summary()
    |> put_summary(exit_code, current_line)

    {exit_code, Language.put_failures_first(server_state, mix_test_output)}
  end

  defp trim_line_number(test_failure_with_line_number) do
    test_failure_with_line_number |> String.split(":") |> hd()
  end
end
