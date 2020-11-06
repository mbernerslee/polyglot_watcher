defmodule PolyglotWatcher.FileSystemChange do
  alias PolyglotWatcher.Languages

  @extensions_to_modules Languages.extensions_to_modules()

  def determine_language_module(file_path, server_state) do
    file_path
    |> parse_file_path()
    |> determine_language_module_actions(server_state)
  end

  defp parse_file_path(file_path) do
    case String.split(file_path, "./") do
      [_, relative_file_path] ->
        {:ok, %{file_path: relative_file_path, extension: Path.extname(relative_file_path)}}

      _ ->
        :error
    end
  end

  defp determine_language_module_actions(:error, server_state), do: {:noop, server_state}

  defp determine_language_module_actions({:ok, file_path}, server_state) do
    case Map.get(@extensions_to_modules, file_path.extension) do
      nil -> {:noop, server_state}
      module -> {module, file_path, server_state}
    end
  end
end
