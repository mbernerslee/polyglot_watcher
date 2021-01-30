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
  def determine_actions(_user_input, _server_state) do
    :no_actions
  end
end
