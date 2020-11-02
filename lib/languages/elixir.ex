defmodule PolyglotWatcher.Languages.Elixir do
  alias PolyglotWatcher.Echo

  @ex ".ex"
  @exs ".exs"
  @test "test"

  def ex, do: @ex
  def exs, do: @exs

  def determine_actions(%{extension: @ex, file_path: file_path}) do
    file_path |> test_path() |> actions()
  end

  def determine_actions(%{extension: @exs, file_path: test_path}) do
    actions(test_path)
  end

  defp actions(test_path) do
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
end
