defmodule PolyglotWatcher.Executor do
  alias PolyglotWatcher.Executor.Real

  def run_actions({actions, server_state}) do
    module().run_actions({actions, server_state})
  end

  defp module do
    Application.get_env(:polyglot_watcher, :executor, Real)
  end
end

defmodule PolyglotWatcher.Executor.Real do
  alias PolyglotWatcher.Puts

  def run_actions({%{run: actions, next: next}, server_state}) do
    {actions, server_state}
    |> run_series_of_actions()
    |> run_actions_tree(next)
  end

  def run_actions({actions, server_state}) when is_list(actions) do
    {_last_action_result, server_state} = run_series_of_actions({actions, server_state})
    server_state
  end

  def run_actions({_, server_state}), do: server_state

  defp run_actions_tree({_last_action_result, server_state}, nil), do: server_state

  defp run_actions_tree({prev_action_result, server_state}, next) do
    actions = next[prev_action_result] || next[:fallback]

    server_state = update_server_state(next, server_state)

    {actions_result, server_state} =
      case actions do
        %{loop_entry_point: loop_entry_point, actions: actions} ->
          loop_through_actions(actions, loop_entry_point, server_state)

        %{run: _} ->
          run_series_of_actions({actions[:run] || [], server_state})
      end

    run_actions_tree({actions_result, server_state}, actions[:next])
  end

  defp loop_through_actions(all_actions, action_key, server_state) do
    action = all_actions[action_key]
    server_state = update_server_state(action, server_state)

    {series_result, server_state} = run_series_of_actions({action.run, server_state})

    next_action = action.next[series_result] || action.next[:fallback]

    server_state = update_server_state(next_action, server_state)

    case next_action do
      %{run: to_run, continue: next_action} ->
        {_series_result, server_state} = run_series_of_actions({to_run, server_state})
        loop_through_actions(all_actions, next_action, server_state)

      %{run: to_run} ->
        run_series_of_actions({to_run, server_state})

      :exit ->
        {series_result, server_state}
    end
  end

  defp update_server_state(%{update_server_state: updater}, server_state) do
    updater.(server_state)
  end

  defp update_server_state(_, server_state) do
    server_state
  end

  defp run_series_of_actions({nil, server_state}), do: {nil, server_state}

  defp run_series_of_actions({actions, server_state}) do
    Enum.reduce(actions, {nil, server_state}, fn action, {_prev_result, server_state} ->
      run_action(action, server_state)
    end)
  end

  defp run_action({:run_sys_cmd, cmd, args}, server_state) do
    {System.cmd(cmd, args, into: IO.stream(:stdio, :line)), server_state}
  end

  defp run_action({:puts, message}, server_state) do
    {Puts.on_new_line(message, :magenta), server_state}
  end

  defp run_action({:puts, colour, message}, server_state) do
    {Puts.on_new_line(message, colour), server_state}
  end

  defp run_action({:write, message}, server_state) do
    {Puts.append(message, :magenta), server_state}
  end

  defp run_action({:write, colour, message}, server_state) do
    {Puts.append(message, colour), server_state}
  end

  # TODO use hoyons magic to solve the problem of wanting text to output on the screen line by line AND save it to a variable for parsing
  defp run_action({:module_action, module, args}, server_state) do
    module.run_action(args, server_state)
  end

  defp run_action({:run_elixir_fn, fun}, server_state), do: {fun.(), server_state}
end

defmodule PolyglotWatcher.Executor.Test do
  def run_actions({_actions, server_state}) do
    server_state
  end
end
