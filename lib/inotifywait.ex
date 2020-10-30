defmodule PolyglotWatcher.Inotifywait do
  alias PolyglotWatcher.Languages

  @extensions %{
    Languages.Elixir.ex() => Languages.Elixir,
    Languages.Elixir.exs() => Languages.Elixir
  }

  def run_watcher_actions(output) do
    output
    |> parse_inotifywait_output()
    |> determine_language_module_actions()
    |> run_actions()
  end

  defp run_actions(actions), do: Enum.map(actions, &run_action/1)

  defp run_action({:run_sys_cmd, cmd, args}) do
    # System.cmd(cmd, args, into: IO.stream(:stdio, :line))
    # System.cmd("mix", ["test", "--color"], into: IO.stream(:stdio, :line))

    command =
      "MIX_ENV=test /usr/bin/mix do run -e 'Application.put_env(:elixir, :ansi_enabled, true);', test"

    Path.join(:code.priv_dir(:polyglot_watcher), "zombie_killer")
    |> IO.inspect()
    |> System.cmd(["sh", "-c", command], into: IO.stream(:stdio, :line))

    # paths = Path.wildcard("test/**/*_test.exs")
    # Mix.Compilers.Test.require_and_run(paths, ["test"], formatters: [ExUnit.CLIFormatter])

    # System.cmd(System.find_executable("mix"), args, into: IO.stream(:stdio, :line))
  end

  defp determine_language_module_actions(file_path) do
    case Map.get(@extensions, file_path.extension) do
      nil -> []
      module -> module.determine_actions(file_path)
    end
  end

  defp parse_inotifywait_output(output) do
    [dir, _event, file_name] = String.split(output)

    file_path =
      [dir, file_name]
      |> Path.join()
      |> Path.relative_to(".")

    extension = Path.extname(file_path)

    %{file_path: file_path, extension: extension}
  end
end
