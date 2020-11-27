defmodule PolyglotWatcher.Languages.ExampleLanguageModule do
  alias PolyglotWatcher.Languages.Language
  @behaviour Language

  @impl Language
  def file_extensions do
    [".cool"]
  end

  @impl Language
  def determine_actions(_file, server_state) do
    {[{:puts, "hello there mother!"}], Map.put(server_state, :modified, "server state")}
  end
end

defmodule PolyglotWatcher.LanguagesTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.Languages
  alias PolyglotWatcher.Languages.ExampleLanguageModule
  alias PolyglotWatcher.Languages.Elixir, as: ElixirLang

  describe "determine_actions/1" do
    test "given noop, returns empty list of actions" do
      server_state = %{some: "map"}
      assert Languages.determine_actions({:noop, server_state}) == {[], server_state}
    end

    test "given a langauge module, runs its determine actions function" do
      server_state = %{some: "map"}

      result =
        Languages.determine_actions(
          {ExampleLanguageModule, %{extension: ".cool", file_path: "cool/file.cool"},
           server_state}
        )

      assert {actions, new_server_state} = result
      assert actions == [{:puts, "hello there mother!"}]
      assert new_server_state == %{some: "map", modified: "server state"}
    end
  end

  @ex ElixirLang.ex()
  @exs ElixirLang.exs()

  describe "extensions_to_modules/0" do
    test "puts in the elixir extensions to language module map" do
      assert %{@ex => ElixirLang, @exs => ElixirLang} = Languages.extensions_to_modules()
    end
  end
end
