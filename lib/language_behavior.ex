defmodule PolyglotWatcher.LanguageBehaviour do
  @type file_path :: %{extension: String.t(), file_path: String.t()}
  @callback file_extensions() :: List.t()
  @callback starting_state() :: {atom(), Map.t()}
  @callback determine_actions(file_path, Map.t()) :: {Map.t() | List.t(), Map.t()}
end
