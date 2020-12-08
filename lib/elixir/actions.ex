defmodule PolyglotWatcher.Elixir.Actions do
  alias PolyglotWatcher.Puts
  alias PolyglotWatcher.Elixir.Language

  # TODO collapse this module into Elixir.Language?

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

  defp spinner, do: spawn(fn -> spin() end)

  defp spin do
    Puts.write(".", :green)
    :timer.sleep(500)
    spin()
  end

  # TODO add spinner tests somehow?
  def run_action(:mix_test_quietly, server_state) do
    spinner_pid = spinner()
    {output, exit_code} = System.cmd("mix", ["test", "--color"])
    Process.exit(spinner_pid, :kill)
    IO.puts("")
    summary = Language.mix_test_summary(output)

    if exit_code == 0 do
      Puts.put(summary, :green)
    else
      Puts.put(summary, :red)
    end

    {exit_code, Language.add_mix_test_history(server_state, output)}
  end

  def run_action({:mix_test, path}, server_state) do
    {output, exit_code} = System.cmd("mix", ["test", path, "--color"])
    IO.puts(output)
    {exit_code, Language.add_mix_test_history(server_state, output)}
  end

  def run_action(:mix_test, server_state) do
    {output, exit_code} = System.cmd("mix", ["test", "--color"])
    IO.puts(output)
    {exit_code, Language.reset_mix_test_history(server_state, output)}
  end

  def run_action(:mix_test_head_single, server_state) do
    case server_state.elixir.failures do
      [] ->
        raise "i expected there to be at least one failing test in my memory, but there were none"

      [failure | _rest] ->
        run_action({:mix_test, failure}, server_state)
    end
  end

  def run_action(:mix_test_head_file_quietly, server_state) do
    case server_state.elixir.failures do
      [] ->
        raise "i expected there to be at least one failing test in my memory, but there were none"

      [failure | _rest] ->
        file = trim_line_number(failure)
        spinner_pid = spinner()
        {output, exit_code} = System.cmd("mix", ["test", file, "--color"])
        Process.exit(spinner_pid, :kill)
        IO.puts("")
        summary = Language.mix_test_summary(output)

        if exit_code == 0 do
          Puts.put(summary, :green)
        else
          Puts.put(summary, :red)
        end

        {exit_code, Language.add_mix_test_history(server_state, output)}
    end
  end

  defp trim_line_number(test_failure_with_line_number) do
    test_failure_with_line_number |> String.split(":") |> hd()
  end
end
