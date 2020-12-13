defmodule PolyglotWatcher.ExampleLanguages.Blueberry.Language do
  alias PolyglotWatcher.LanguageBehaviour

  @behaviour LanguageBehaviour

  @impl LanguageBehaviour
  def file_extensions do
    [".blueb"]
  end

  @impl LanguageBehaviour
  def starting_state, do: {:blueb, %{plant: :bush, colour: :blue, harvest: false, nom: false}}

  @impl LanguageBehaviour
  def determine_actions(_file_path, server_state) do
    {[], server_state}
  end
end
