defmodule PolyglotWatcher.FileSystemChangeTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.{FileSystemChange, ServerStateBuilder}
  alias PolyglotWatcher.Languages.Elixir, as: ElixirLang

  describe "determine_language_module/2" do
    test "given jank returns no actions & does not change the server state" do
      server_state = ServerStateBuilder.build()

      assert {:noop, server_state} ==
               FileSystemChange.determine_language_module(
                 "/home/berners/src/polyglot_watcher/./_build/test/lib/polyglot_watcher/.mix/.mix_test_failures",
                 server_state
               )
    end

    test "given an elixir test file saved" do
      server_state = ServerStateBuilder.build()

      assert {ElixirLang, %{extension: ".exs", file_path: "test/file_system_change_test.exs"},
              server_state} ==
               FileSystemChange.determine_language_module(
                 "/home/berners/src/polyglot_watcher/./test/file_system_change_test.exs",
                 server_state
               )
    end

    test "given an elixir lib file saved" do
      server_state = ServerStateBuilder.build()

      assert {ElixirLang, %{extension: ".ex", file_path: "lib/file_system_change.ex"},
              server_state} ==
               FileSystemChange.determine_language_module(
                 "/home/berners/src/polyglot_watcher/./lib/file_system_change.ex",
                 server_state
               )
    end

    test "given some arbitrary file saved, that doesn't match with any supported langauge" do
      server_state = ServerStateBuilder.build()

      assert {:noop, server_state} ==
               FileSystemChange.determine_language_module(
                 "/home/berners/src/polyglot_watcher/./cool/cool_file.cool",
                 server_state
               )
    end
  end
end
