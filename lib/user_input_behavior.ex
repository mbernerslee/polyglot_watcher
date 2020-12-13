defmodule PolyglotWatcher.UserInputBehaviour do
  @callback prefix() :: String.t()
  @callback usage() :: String.t()
  @callback determine_actions(String.t(), Map.t()) ::
              {:ok, {Map.t() | List.t(), Map.t()}} | :error
end
