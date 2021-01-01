defmodule PolyglotWatcher.Elm.LanguageTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.ServerStateBuilder
  alias PolyglotWatcher.Elm.Language, as: Elm
  alias PolyglotWatcher.Elm.Actions

  describe "determine_actions/2" do
    test "runs elm make from the directory that elm.json is in" do
      file = %{extension: ".elm", file_path: "test/elm_examples/simplest_project/src/Main.elm"}
      server_state = ServerStateBuilder.build()

      assert {[
                {:cd, "test/elm_examples/simplest_project"},
                {:module_action, Actions, {:make, "src/Main.elm"}},
                {:cd, "-"}
              ], server_state} = Elm.determine_actions(file, server_state)
    end

    # TODO add a test for when elm json and or main are not found
  end
end
