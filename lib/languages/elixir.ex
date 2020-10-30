defmodule PolyglotWatcher.Languages.Elixir do
  @ex ".ex"
  @exs ".exs"
  @lib "lib"
  @test "test"

  def ex, do: @ex
  def exs, do: @exs

  def determine_actions(%{extension: @ex, file_path: file_path}) do
    [{:run_sys_cmd, "mix", ["test", test_path(file_path), "--color"]}]
  end

  defp test_path(file_path) do
    [_head | rest] = Path.split(file_path)
    file_name = rest |> Enum.reverse() |> hd() |> Path.basename(@ex)
    middle = rest |> Enum.reverse() |> tl() |> Enum.reverse()

    Path.join([@test] ++ middle ++ ["#{file_name}_#{@test}#{@exs}"])
  end
end
