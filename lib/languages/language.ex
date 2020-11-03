defmodule PolyglotWatcher.Languages.Language do
  @type file_path :: %{extension: String.t(), file_path: String.t()}
  @callback determine_actions(file_path, Map.t()) :: {Map.t() | List.t(), Map.t()}
  @callback file_extensions() :: List.t()
end
