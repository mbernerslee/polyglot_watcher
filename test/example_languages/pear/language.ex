defmodule PolyglotWatcher.ExampleLanguages.Pear.Language do
  alias PolyglotWatcher.LanguageBehaviour

  @behaviour LanguageBehaviour

  @impl LanguageBehaviour
  def file_extensions do
    [".pear"]
  end

  @impl LanguageBehaviour
  def starting_state do
    {:pear, %{juicy: true, tasty: true, pick: false, eat: false, peel: false}}
  end

  @impl LanguageBehaviour
  def determine_actions(_file_path, server_state) do
    {[], server_state}
  end
end
