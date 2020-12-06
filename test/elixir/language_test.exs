defmodule PolyglotWatcher.Elixir.LanguageTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.Elixir.Language
  alias PolyglotWatcher.Elixir.Actions
  alias PolyglotWatcher.ServerStateBuilder

  @ex Language.ex()
  @exs Language.exs()

  describe "determine_actions/2 - fix_all mode" do
    test "runs mix test regardless of which file changed" do
      failures = [
        "test/elixir/language_test.exs:10",
        "test/elixir/language_test.exs:24"
      ]

      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(failures)
        |> ServerStateBuilder.with_elixir_fix_all_mode(:single_test)

      assert {actions, _new_server_state} =
               Language.determine_actions(
                 %{extension: @ex, file_path: "lib/elixir/language.ex"},
                 server_state
               )

      assert %{
               run: [],
               next: %{
                 :fallback => %{loop_entry_point: :single_test}
               }
             } = actions
    end
  end

  describe "determine_actions/2 - default mode" do
    test "finds the equivalent test file" do
      server_state = ServerStateBuilder.build()

      assert {actions, _new_server_state} =
               Language.determine_actions(
                 %{extension: @ex, file_path: "lib/very/cool.ex"},
                 server_state
               )

      assert %{
               next: %{
                 false: %{
                   run: [
                     {:run_sys_cmd, "tput", ["reset"]},
                     {:puts, "No test found at test/very/cool_test.exs"},
                     {:puts, "Uh-oh, You don't have tests for this do you?"}
                   ]
                 },
                 true: %{
                   run: [
                     {:run_sys_cmd, "tput", ["reset"]},
                     {:puts, "Running mix test test/very/cool_test.exs"},
                     {:module_action, Actions, {:mix_test, "test/very/cool_test.exs"}}
                   ]
                 }
               },
               run: [
                 run_elixir_fn: _fun
               ]
             } = actions
    end

    test "the server_state is not updated" do
      server_state = ServerStateBuilder.build()

      assert {_actions, ^server_state} =
               Language.determine_actions(
                 %{extension: @ex, file_path: "lib/very/cool.ex"},
                 server_state
               )
    end

    test "given a lib file that doesn't exist, the find file function returns false" do
      server_state = ServerStateBuilder.build()

      assert {actions, _new_server_state} =
               Language.determine_actions(
                 %{extension: @ex, file_path: "lib/very/cool.ex"},
                 server_state
               )

      assert %{run: [run_elixir_fn: fun]} = actions

      assert fun.() == false
    end

    test "given a lib file that realtes to a test that DOES exist, the find file function returns true" do
      server_state = ServerStateBuilder.build()

      assert {actions, _new_server_state} =
               Language.determine_actions(
                 %{extension: @ex, file_path: "lib/elixir/language.ex"},
                 server_state
               )

      assert %{run: [run_elixir_fn: fun]} = actions

      assert fun.() == true
    end

    test "given a test that DOES exist, the find file function returns true" do
      server_state = ServerStateBuilder.build()

      assert {actions, _new_server_state} =
               Language.determine_actions(
                 %{extension: @exs, file_path: "test/elixir/language_test.exs"},
                 server_state
               )

      assert %{run: [run_elixir_fn: fun]} = actions

      assert fun.() == true
    end

    test "given a test that doesn't exist, the find file function returns false" do
      server_state = ServerStateBuilder.build()

      assert {actions, _new_server_state} =
               Language.determine_actions(
                 %{extension: @exs, file_path: "test/nonsense/path/jank_test.exs"},
                 server_state
               )

      assert %{run: [run_elixir_fn: fun]} = actions

      assert fun.() == false
    end
  end

  describe "determine_actions/2 - fixed_previous mode" do
    test "regardless of file, returns actions to run the test stored in the head of failed" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_fixed_previous_mode()
        |> ServerStateBuilder.with_elixir_failures(["test/languages/elixir_test.exs:103"])

      assert {actions, _new_server_state} =
               Language.determine_actions(
                 %{extension: @exs, file_path: "test/nonsense/path/jank_test.exs"},
                 server_state
               )

      assert [
               {:run_sys_cmd, "tput", ["reset"]},
               {:puts, "Running 'mix test test/languages/elixir_test.exs:103'"},
               {:module_action, Actions, {:mix_test, "test/languages/elixir_test.exs:103"}},
               {:puts, "I've been told to ONLY run this one FIXED path btw!"},
               {:puts, "Retern to default mode by entering 'ex d'"}
             ] = actions
    end

    test "returns the default mode options if there is no test in the failures list" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_fixed_previous_mode()
        |> ServerStateBuilder.with_elixir_failures([])

      assert {actions, _new_server_state} =
               Language.determine_actions(
                 %{extension: @exs, file_path: "test/nonsense/path/jank_test.exs"},
                 server_state
               )

      assert %{run: [run_elixir_fn: _fun]} = actions
    end
  end

  describe "determine_actions/2 - fixed_file mode" do
    test "regardless of file, returns actions to run the test stored in the head of failed" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_fixed_file_mode("test/languages/elixir_test.exs:103")

      assert {actions, _new_server_state} =
               Language.determine_actions(
                 %{extension: @exs, file_path: "test/nonsense/path/jank_test.exs"},
                 server_state
               )

      assert [
               {:run_sys_cmd, "tput", ["reset"]},
               {:puts, "Running 'mix test test/languages/elixir_test.exs:103'"},
               {:module_action, Actions, {:mix_test, "test/languages/elixir_test.exs:103"}},
               {:puts, "I've been told to ONLY run this one FIXED path btw!"},
               {:puts, "Retern to default mode by entering 'ex d'"}
             ] = actions
    end
  end

  describe "add_mix_test_history/2" do
    test "adds failing tests to the failures" do
      server_state = ServerStateBuilder.build() |> ServerStateBuilder.with_elixir_failures([])

      test_output = """
        1) test add_mix_test_history/2 adds failing tests to the failures (PolyglotWatcher.Languages.ElixirTest)
           test/languages/elixir_test.exs:154
           Flunked!
           code: flunk()
           stacktrace:
            test/languages/elixir_test.exs:157: (test)

      ........

      Finished in 0.1 seconds
      9 tests, 1 failure

      Randomized with seed 846778
      """

      result = Language.add_mix_test_history(server_state, test_output)
      assert %{elixir: %{failures: ["test/languages/elixir_test.exs:154"]}} = result
    end

    test "with 2 failures & one existing failure in the list" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(["test/existing_test.exs:10"])

      test_output = """
        1) test determine_actions/2 - fixed_previous mode returns the default mode options if there is no test in the failures list (PolyglotWatcher.Languages.ElixirTest)
           test/languages/elixir_test.exs:137
           Flunked!
           code: flunk()
           stacktrace:
             test/languages/elixir_test.exs:150: (test)

      .......

        2) test add_mix_test_history/2 adds failing tests to the failures (PolyglotWatcher.Languages.ElixirTest)
           test/languages/elixir_test.exs:155
           Flunked!
           code: flunk()
           stacktrace:
             test/languages/elixir_test.exs:174: (test)



      Finished in 0.1 seconds
      9 tests, 2 failures

      Randomized with seed 394164
      """

      assert %{
               elixir: %{
                 failures: [
                   "test/languages/elixir_test.exs:155",
                   "test/languages/elixir_test.exs:137",
                   "test/existing_test.exs:10"
                 ]
               }
             } = Language.add_mix_test_history(server_state, test_output)
    end

    test "doesn't add duplicate failures" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(["test/languages/elixir_test.exs:154"])

      test_output = """
        1) test add_mix_test_history/2 adds failing tests to the failures (PolyglotWatcher.Languages.ElixirTest)
           test/languages/elixir_test.exs:154
           Flunked!
           code: flunk()
           stacktrace:
            test/languages/elixir_test.exs:157: (test)

      ........

      Finished in 0.1 seconds
      9 tests, 1 failure

      Randomized with seed 846778
      """

      result = Language.add_mix_test_history(server_state, test_output)
      assert %{elixir: %{failures: ["test/languages/elixir_test.exs:154"]}} = result
    end
  end

  describe "reset_mix_test_history/2" do
    test "removed failures & adds only new ones" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(["test/path_test.exs"])

      test_output = """
        1) test add_mix_test_history/2 adds failing tests to the failures (PolyglotWatcher.Languages.ElixirTest)
           test/languages/elixir_test.exs:154
           Flunked!
           code: flunk()
           stacktrace:
            test/languages/elixir_test.exs:157: (test)

      ........

      Finished in 0.1 seconds
      9 tests, 1 failure

      Randomized with seed 846778
      """

      result = Language.reset_mix_test_history(server_state, test_output)
      assert %{elixir: %{failures: ["test/languages/elixir_test.exs:154"]}} = result
    end
  end
end
