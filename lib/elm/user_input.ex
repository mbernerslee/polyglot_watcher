defmodule PolyglotWatcher.Elm.UserInput do
  alias PolyglotWatcher.Elm.Usage
  alias PolyglotWatcher.UserInputBehaviour

  @behaviour UserInputBehaviour
  @prefix "elm"

  @impl UserInputBehaviour
  def prefix, do: @prefix

  @impl UserInputBehaviour
  defdelegate usage, to: Usage

  @impl UserInputBehaviour
  def determine_actions(user_input, server_state) do
    :error
  end
end
