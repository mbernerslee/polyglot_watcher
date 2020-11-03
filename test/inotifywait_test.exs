defmodule PolyglotWatcher.InotifywaitTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.Inotifywait
  alias PolyglotWatcher.Languages.Elixir, as: ElixirLang

  describe "determine_language_module/2" do
    test "given jank returns no actions & does not change the server state" do
      server_state = %{port: "port", elixir: %{mode: :default, failures: []}}

      assert {:noop, server_state} ==
               Inotifywait.determine_language_module(
                 "./test/ CLOSE_WRITE,CLOSE 4913\n",
                 server_state
               )
    end

    test "given an elixir test file saved" do
      server_state = %{port: "port", elixir: %{mode: :default, failures: []}}

      assert {ElixirLang, %{extension: ".exs", file_path: "test/inotifywait_test.exs"},
              server_state} ==
               Inotifywait.determine_language_module(
                 "./test/ CLOSE_WRITE,CLOSE inotifywait_test.exs\n",
                 server_state
               )
    end

    test "given an elixir lib file saved" do
      server_state = %{port: "port", elixir: %{mode: :default, failures: []}}

      assert {ElixirLang, %{extension: ".ex", file_path: "lib/inotifywait.ex"}, server_state} ==
               Inotifywait.determine_language_module(
                 "./lib/ CLOSE_WRITE,CLOSE inotifywait.ex\n",
                 server_state
               )
    end

    test "given some arbitrary file saved, that doesn't match with any supported langauge" do
      server_state = %{port: "port", elixir: %{mode: :default, failures: []}}

      assert {:noop, server_state} ==
               Inotifywait.determine_language_module(
                 "./cool/ CLOSE_WRITE,CLOSE cool.cool\n",
                 server_state
               )
    end
  end
end
