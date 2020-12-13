defmodule PolyglotWatcher.UserInputTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.{ServerStateBuilder, UserInput}
  alias FakeLanguage.{Pear, Blueberry}
  alias PolyglotWatcher.ExampleLanguages.Blueberry.UserInputParser, as: Blueberry
  alias PolyglotWatcher.ExampleLanguages.Pear.UserInputParser, as: Pear

  @fake_languages [Pear, Blueberry]

  describe "determine_startup_actions/3" do
    test "with no CLI args" do
      server_state = ServerStateBuilder.without_watcher_pid(ServerStateBuilder.build())

      assert {:ok,
              {[{:run_sys_cmd, "tput", ["reset"]}, _, {:puts, "Watching in default mode..."}],
               ^server_state}} =
               UserInput.determine_startup_actions([], server_state, @fake_languages)
    end

    test "with recognised CLI args" do
      server_state = ServerStateBuilder.without_watcher_pid(ServerStateBuilder.build())

      assert {:ok,
              {[
                 {:run_sys_cmd, "tput", ["reset"]},
                 {:puts,
                  [
                    white: "type ",
                    cyan: "help",
                    white:
                      " into this terminal to see a list of options and how to change watcher modes as I run"
                  ]},
                 {:puts, "eat"}
               ],
               updated_server_state}} =
               UserInput.determine_startup_actions(["pear", "eat"], server_state, @fake_languages)

      assert Map.put(server_state, :eat, true) == updated_server_state

      assert {:ok,
              {[
                 {:run_sys_cmd, "tput", ["reset"]},
                 {:puts,
                  [
                    white: "type ",
                    cyan: "help",
                    white:
                      " into this terminal to see a list of options and how to change watcher modes as I run"
                  ]},
                 {:puts, "eat"}
               ],
               updated_server_state}} =
               UserInput.determine_startup_actions(["pear", "eat"], server_state, @fake_languages)

      assert Map.put(server_state, :eat, true) == updated_server_state
    end

    test "with unrecognised CLI args" do
      server_state = ServerStateBuilder.without_watcher_pid(ServerStateBuilder.build())

      assert {:error,
              {[
                 {:run_sys_cmd, "tput", ["reset"]},
                 {:puts,
                  [
                    {:green, "how to use pear"},
                    {:red, "how to use blueb"},
                    {:white, "\n"},
                    {:red, "I didn't understand the command line arguments 'nonsense'\n"},
                    {:red, "The supported arguments are listed above\n\n"}
                  ]}
               ],
               ^server_state}} =
               UserInput.determine_startup_actions(["nonsense"], server_state, @fake_languages)
    end
  end

  describe "determine_actions/3" do
    test "when given language user_input modules, returns any actions from them which can be determined" do
      server_state = ServerStateBuilder.build()

      result = UserInput.determine_actions("pear pick\n", server_state, @fake_languages)
      assert {[{:puts, "pick"}], %{pick: true}} = result

      result = UserInput.determine_actions("blueb harvest\n", server_state, @fake_languages)
      assert {[{:puts, "harvest"}], %{harvest: true}} = result

      result = UserInput.determine_actions("pear eat\n", server_state, @fake_languages)
      assert {[{:puts, "eat"}], %{eat: true}} = result

      result = UserInput.determine_actions("blueb nom\n", server_state, @fake_languages)
      assert {[{:puts, "nom"}], %{nom: true}} = result
    end

    test "given language agnostic input commands" do
      server_state = ServerStateBuilder.build()

      result = UserInput.determine_actions("c\n", server_state, @fake_languages)
      assert {[{:run_sys_cmd, "tput", ["reset"]}], ^server_state} = result
    end

    test "when given something that's not understood at all, prints the usage" do
      server_state = ServerStateBuilder.build()

      usage = UserInput.usage(@fake_languages)

      result = UserInput.determine_actions("pear nonsense\n", server_state, @fake_languages)
      assert {[{:puts, ^usage}], ^server_state} = result

      result = UserInput.determine_actions("blueb nonsense\n", server_state, @fake_languages)
      assert {[{:puts, ^usage}], ^server_state} = result

      result = UserInput.determine_actions("some nonesense\n", server_state, @fake_languages)
      assert {[{:puts, ^usage}], ^server_state} = result
    end
  end

  describe "usage/1" do
    test "returns the usage detailed in all language modules" do
      usage = UserInput.usage(@fake_languages)

      assert usage == [
               {:white, "Usage\n\n"},
               {:yellow, "# General\n"},
               {:white, "  • "},
               {:cyan, "c"},
               {:white, "  clears the screen\n"},
               {:white, "  • "},
               {:cyan, "any unrecognised input"},
               {:white, "  prints this message"},
               {:white, "\n\n"},
               {:green, "how to use pear"},
               {:red, "how to use blueb"}
             ]
    end
  end

  describe "parse/2" do
    test "returns the string after the prefix" do
      assert UserInput.parse("ex fa", "ex") == {:ok, "fa"}
      assert UserInput.parse("ex exfa", "ex") == {:ok, "exfa"}
      assert UserInput.parse("ex ex fa", "ex") == {:ok, "ex fa"}
      assert UserInput.parse("ex test/path_test.exs", "ex") == {:ok, "test/path_test.exs"}
    end

    test "errors when there's no at the start, or if there's no space" do
      assert UserInput.parse("nope", "ex") == :error
      assert UserInput.parse("nopex", "ex") == :error
      assert UserInput.parse("exhello", "ex") == :error
      assert UserInput.parse("nope ex nope", "ex") == :error
      assert UserInput.parse("nope ex", "ex") == :error
    end
  end
end
