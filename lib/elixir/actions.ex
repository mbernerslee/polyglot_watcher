defmodule PolyglotWatcher.Elixir.Actions do
  alias PolyglotWatcher.Elixir.Language

  # TODO collapse this module into Elixir.Language?

  def mix_test do
    {:module_action, __MODULE__, :mix_test}
  end

  def mix_test(test_path) do
    {:module_action, __MODULE__, {:mix_test, test_path}}
  end

  def mix_test_head_single do
    {:module_action, __MODULE__, :mix_test_head_single}
  end

  def mix_test_head_file do
    {:module_action, __MODULE__, :mix_test_head_file}
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

  def run_action(:mix_test_head_file, server_state) do
    case server_state.elixir.failures do
      [] ->
        raise "i expected there to be at least one failing test in my memory, but there were none"

      [failure | _rest] ->
        file = trim_line_number(failure)
        run_action({:mix_test, file}, server_state)
    end
  end

  defp trim_line_number(test_failure_with_line_number) do
    test_failure_with_line_number |> String.split(":") |> hd()
  end
end
