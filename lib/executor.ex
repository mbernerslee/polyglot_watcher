defmodule PolyglotWatcher.Executor do
  defp run_actions(%{run: actions, next: next}) do
    actions
    |> run_series_of_actions()
    |> run_actions(next)
  end

  defp run_actions(_), do: nil

  defp run_actions(result, nil), do: result

  defp run_actions(result, next) do
    actions = next[result]
    result = run_series_of_actions(actions.run)
    run_actions(result, actions[next])
  end

  defp run_series_of_actions(actions) do
    Enum.reduce(actions, nil, fn action, _acc -> run_action(action) end)
  end

  defp run_action({:run_sys_cmd, cmd, args}) do
    System.cmd(cmd, args, into: IO.stream(:stdio, :line))
  end

  defp run_action({:mix_test, path}) do
    {output, _} = System.cmd("mix", ["test", path, "--color"])
    IO.puts(output)
  end

  defp run_action({:run_elixir_fn, fun}), do: fun.()
end
