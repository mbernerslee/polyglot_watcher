defmodule PolyglotWatcher.Languages.Elixir do
  alias PolyglotWatcher.Echo
  alias PolyglotWatcher.Languages.Language
  @behaviour Language

  @ex ".ex"
  @exs ".exs"
  @test "test"

  def ex, do: @ex
  def exs, do: @exs

  @impl Language
  def file_extensions do
    [@ex, @exs]
  end

  @impl Language
  def determine_actions(file, server_state) do
    case mode(server_state) do
      {:fixed_previous, test_path} ->
        fixed_path(test_path, server_state)

      {:fixed_file, test_path} ->
        fixed_path(test_path, server_state)

      _ ->
        default_mode(file, server_state)
    end
  end

  defp fixed_path(test_path, server_state) do
    {[
       {:run_sys_cmd, "tput", ["reset"]},
       {:run_sys_cmd, "echo", Echo.pink("Running 'mix test #{test_path}'")},
       {:mix_test, test_path},
       {:run_sys_cmd, "echo", Echo.pink("I've been told to ONLY run this one FIXED path btw!")},
       {:run_sys_cmd, "echo", Echo.pink("Retern to default mode by entering 'ex d'")}
     ], server_state}
  end

  defp default_mode(%{extension: @ex, file_path: file_path}, server_state) do
    {file_path |> test_path() |> default_mode(), server_state}
  end

  defp default_mode(%{extension: @exs, file_path: test_path}, server_state) do
    {default_mode(test_path), server_state}
  end

  def reset_mix_test_history(server_state, mix_test_output) do
    server_state
    |> put_in([:elixir, :failures], [])
    |> add_mix_test_history(mix_test_output)
  end

  def add_mix_test_history(server_state, mix_test_output) do
    mix_test_output = String.split(mix_test_output, "\n")
    failures = accumulate_failing_tests([], nil, mix_test_output)

    update_in(server_state, [:elixir, :failures], fn old -> failures ++ old end)
  end

  defp accumulate_failing_tests(acc, _, []), do: acc

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
            {:run_sys_cmd, "echo", Echo.pink("Running mix test #{test_path}")},
            {:mix_test, test_path}
          ]
        },
        false => %{
          run: [
            {:run_sys_cmd, "tput", ["reset"]},
            {:run_sys_cmd, "echo", Echo.pink("No test found at #{test_path}")},
            {:run_sys_cmd, "echo", Echo.pink("Uh-oh, You don't have tests for this do you?")}
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
end
