defmodule PolyglotWatcher.Inotifywait do
  alias PolyglotWatcher.Languages

  @extensions_to_modules Languages.extensions_to_modules()

  def determine_language_module(output, server_state) do
    output
    |> parse_inotifywait_output()
    |> determine_language_module_actions(server_state)
  end

  defp determine_language_module_actions(:error, server_state), do: {:noop, server_state}

  defp determine_language_module_actions({:ok, file_path}, server_state) do
    case Map.get(@extensions_to_modules, file_path.extension) do
      nil -> {:noop, server_state}
      module -> {module, file_path, server_state}
    end
  end

  defp parse_inotifywait_output(output) do
    case String.split(output) do
      [dir, _event, file_name | _] ->
        file_path =
          [dir, file_name]
          |> Path.join()
          |> Path.relative_to(".")

        {:ok, %{file_path: file_path, extension: Path.extname(file_path)}}

      _ ->
        :error
    end
  end
end
