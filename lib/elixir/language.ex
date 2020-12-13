defmodule PolyglotWatcher.Elixir.Language do
  alias PolyglotWatcher.LanguageBehaviour
  alias PolyglotWatcher.Elixir.{Actions, FixAllMode}
  @behaviour LanguageBehaviour

  @ex ".ex"
  @exs ".exs"
  @test "test"

  def ex, do: @ex
  def exs, do: @exs

  @impl LanguageBehaviour
  def file_extensions do
    [@ex, @exs]
  end

  @impl LanguageBehaviour
  def starting_state do
    {:elixir, %{mode: :default, failures: []}}
  end

  @impl LanguageBehaviour
  def determine_actions(file, server_state) do
    case mode(server_state) do
      {:fixed_previous, test_path} ->
        fixed_path(test_path, server_state)

      {:fixed_file, test_path} ->
        fixed_path(test_path, server_state)

      {:fix_all, fix_all} ->
        FixAllMode.actions(server_state, fix_all)

      _ ->
        default_mode(file, server_state)
    end
  end

  def reset_mix_test_history(server_state, mix_test_output) do
    server_state
    |> put_in([:elixir, :failures], [])
    |> add_mix_test_history(mix_test_output)
  end

  def add_mix_test_history(server_state, mix_test_output) do
    new_failures = accumulate_failing_tests(mix_test_output)

    update_in(server_state, [:elixir, :failures], fn current_failures ->
      Enum.reduce(new_failures, current_failures, fn new_failure, acc ->
        if Enum.member?(acc, new_failure) do
          acc
        else
          [new_failure | acc]
        end
      end)
    end)
  end

  def update_mix_test_history_for_file(server_state, file, mix_test_output) do
    failures = remove_failures_for_file(server_state, file)
    new_failures = accumulate_failing_tests(mix_test_output)
    put_in(server_state, [:elixir, :failures], new_failures ++ failures)
  end

  def put_failures_first(server_state, mix_test_output) do
    case Regex.named_captures(~r|.*(?<test_file>test.*_test.exs).*|, mix_test_output) do
      %{"test_file" => test_file} ->
        failures = put_failures_for_file_first(server_state.elixir.failures, test_file)
        put_in(server_state, [:elixir, :failures], failures)

      _ ->
        server_state
    end
  end

  defp put_failures_for_file_first(failures, test_file) do
    regex = ~r|^#{test_file}:[0-9]+|
    put_failures_for_file_first(%{append: [], prepend: []}, failures, regex)
  end

  defp put_failures_for_file_first(acc, [], _regex) do
    Enum.reverse(acc.prepend) ++ Enum.reverse(acc.append)
  end

  defp put_failures_for_file_first(acc, [fail | rest], regex) do
    acc =
      if Regex.match?(regex, fail) do
        %{acc | prepend: [fail | acc.prepend]}
      else
        %{acc | append: [fail | acc.append]}
      end

    put_failures_for_file_first(acc, rest, regex)
  end

  defp remove_failures_for_file(server_state, file) do
    regex = ~r|^#{file}:[0-9]+|
    Enum.reject(server_state.elixir.failures, &Regex.match?(regex, &1))
  end

  defp fixed_path(test_path, server_state) do
    {[
       {:run_sys_cmd, "tput", ["reset"]},
       {:puts, "Running 'mix test #{test_path}'"},
       Actions.mix_test(test_path),
       {:puts, "I've been told to ONLY run this one FIXED path btw!"},
       {:puts, "Retern to default mode by entering 'ex d'"}
     ], server_state}
  end

  defp default_mode(%{extension: @ex, file_path: file_path}, server_state) do
    {file_path |> test_path() |> default_mode(), server_state}
  end

  defp default_mode(%{extension: @exs, file_path: test_path}, server_state) do
    {default_mode(test_path), server_state}
  end

  defp accumulate_failing_tests(mix_test_output) do
    mix_test_output = String.split(mix_test_output, "\n")
    accumulate_failing_tests([], nil, mix_test_output)
  end

  defp accumulate_failing_tests(acc, _, []), do: Enum.reverse(acc)

  defp accumulate_failing_tests(acc, :add_next_line, [line | rest]) do
    acc =
      case Regex.named_captures(~r|.*(?<test>test.*_test.exs:[0-9]+).*|, line) do
        %{"test" => test_path} ->
          [test_path | acc]

        _ ->
          acc
      end

    accumulate_failing_tests(acc, nil, rest)
  end

  defp accumulate_failing_tests(acc, nil, [line | rest]) do
    if Regex.match?(~r|^\s+[0-9]+\)\stest|, line) do
      accumulate_failing_tests(acc, :add_next_line, rest)
    else
      accumulate_failing_tests(acc, nil, rest)
    end
  end

  defp default_mode(test_path) do
    %{
      run: [{:run_elixir_fn, fn -> File.exists?(test_path) end}],
      next: %{
        true => %{
          run: [
            {:run_sys_cmd, "tput", ["reset"]},
            {:puts, "Running mix test #{test_path}"},
            Actions.mix_test(test_path)
          ]
        },
        false => %{
          run: [
            {:run_sys_cmd, "tput", ["reset"]},
            {:puts, "No test found at #{test_path}"},
            {:puts, "Uh-oh, You don't have tests for this do you?"}
          ]
        }
      }
    }
  end

  defp test_path(file_path) do
    [_head | rest] = Path.split(file_path)
    file_name = rest |> Enum.reverse() |> hd() |> Path.basename(@ex)
    middle = rest |> Enum.reverse() |> tl() |> Enum.reverse()

    Path.join([@test] ++ middle ++ ["#{file_name}_#{@test}#{@exs}"])
  end

  defp mode(%{elixir: %{mode: mode, failures: failures}}) do
    case {mode, failures} do
      {:fixed_previous, [test_path | _]} -> {:fixed_previous, test_path}
      {:fixed_previous, []} -> :default
      {other, _} -> other
    end
  end

  def set_mode(server_state, mode) do
    put_in(server_state, [:elixir, :mode], mode)
  end

  def mix_test_summary(mix_test_output) do
    case Regex.run(
           ~r/[0-9]* tests?, [0-9]* failures?|0 failures|There are no tests to run/,
           mix_test_output
         ) do
      [result] -> {:ok, result}
      _ -> {:error, mix_test_output}
    end
  end
end
