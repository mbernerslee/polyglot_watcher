defmodule PolyglotWatcher.Elixir.Actions do
  alias PolyglotWatcher.Elixir.Language

  # TODO collapse this module into Elixir.Language?

  def mix_test do
    {:module_action, __MODULE__, :mix_test}
  end

  def mix_test(test_path) do
    {:module_action, __MODULE__, {:mix_test, test_path}}
  end

  def run_action({:mix_test, path}, server_state) do
    {output, exit_code} = System.cmd("mix", ["test", path, "--color"])
    IO.puts("****************************************************")
    IO.puts(output)
    IO.puts(exit_code)
    {exit_code, Language.add_mix_test_history(server_state, output)}
  end

  def run_action(:mix_test, server_state) do
    {output, exit_code} = System.cmd("mix", ["test", "--color"])
    IO.puts("****************************************************")
    IO.puts(output)
    IO.puts(exit_code)
    {exit_code, Language.reset_mix_test_history(server_state, output)}
  end
end
