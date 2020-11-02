defmodule PolyglotWatcher.Inotifywait do
  alias PolyglotWatcher.Languages

  @extensions %{
    Languages.Elixir.ex() => Languages.Elixir,
    Languages.Elixir.exs() => Languages.Elixir
  }

  def determine_actions(output, server_state) do
    output
    |> parse_inotifywait_output()
    |> determine_language_module_actions(server_state)
  end

  defp determine_language_module_actions(file_path, server_state) do
    case Map.get(@extensions, file_path.extension) do
      nil -> {%{}, server_state}
      module -> module.determine_actions(file_path, server_state)
    end
  end

  defp parse_inotifywait_output(output) do
    [dir, _event, file_name | _] = String.split(output)

    file_path =
      [dir, file_name]
      |> Path.join()
      |> Path.relative_to(".")

    extension = Path.extname(file_path)

    %{file_path: file_path, extension: extension}
  end
end
