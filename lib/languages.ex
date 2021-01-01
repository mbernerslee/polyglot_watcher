defmodule PolyglotWatcher.Languages do
  alias PolyglotWatcher.Elixir.Language, as: ElixirLang
  alias PolyglotWatcher.Elm.Language, as: Elm

  @all [ElixirLang, Elm]

  def extensions_to_modules do
    Enum.reduce(@all, %{}, fn language_module, acc ->
      language_module.file_extensions
      |> Enum.map(fn extension -> {extension, language_module} end)
      |> Map.new()
      |> Map.merge(acc)
    end)
  end

  def determine_actions({:noop, server_state}), do: {[], server_state}

  def determine_actions({module, file, server_state}) do
    module.determine_actions(file, server_state)
  end
end
