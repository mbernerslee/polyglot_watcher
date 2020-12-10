defmodule PolyglotWatcher.UserInputParser do
  @callback prefix() :: String.t()
  @callback determine_actions(String.t(), Map.t()) ::
              {:ok, {Map.t() | List.t(), Map.t()}} | :error
end
