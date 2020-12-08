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

  describe "mix_test_summary/1" do
    test "given some mix test output, returns the 'X tests, Y failures' line" do
      output = """
        1) test put/1 puts the message in magenta (PolyglotWatcher.PutsTest)
           test/puts_test.exs:18

           code: flunk("")
           stacktrace:
             test/puts_test.exs:23: (test)



        2) test put/2 all supported colours (PolyglotWatcher.PutsTest)
           test/puts_test.exs:7

           code: flunk("")
           stacktrace:
             test/puts_test.exs:13: (test)

      ................................................

      Finished in 0.4 seconds
      51 tests, 2 failures
      """

      assert Language.mix_test_summary(output) == "51 tests, 2 failures"
    end

    test "with 1 failure" do
      output = """
      1) test put/1 puts the message in magenta (PolyglotWatcher.PutsTest)
      test/puts_test.exs:17

      code: flunk("")
      stacktrace:
       test/puts_test.exs:22: (test)

      .

      Finished in 0.02 seconds
      2 tests, 1 failure

      Randomized with seed 616218
      """

      assert Language.mix_test_summary(output) == "2 tests, 1 failure"
    end

    test "with 1 test" do
      output = """
      1) test put/1 puts the message in magenta (PolyglotWatcher.PutsTest)
      test/puts_test.exs:17

      code: flunk("")
      stacktrace:
       test/puts_test.exs:22: (test)

      .

      Finished in 0.02 seconds
      2 tests, 1 failure

      Randomized with seed 616218
      """

      assert Language.mix_test_summary(output) == "2 tests, 1 failure"
    end

    test "with 1 test & 1 failure" do
      output = """
      1) test put/1 puts the message in magenta (PolyglotWatcher.PutsTest)
      test/puts_test.exs:17

      code: flunk("")
      stacktrace:
        test/puts_test.exs:22: (test)



      Finished in 0.01 seconds
      1 test, 1 failure

      Randomized with seed 413773
      """

      assert Language.mix_test_summary(output) == "1 test, 1 failure"
    end

    test "with 0 tests & 0 failures" do
      output = """
       Finished in 0.01 seconds
      0 failures

      Randomized with seed 342927
      """

      assert Language.mix_test_summary(output) == "0 failures"
    end
  end

  @one_failure """
    1) test update_mix_test_history_for_file/3 replaces all failures for file (PolyglotWatcher.Elixir.LanguageTest)
     test/elixir/language_test.exs:469
     hi
     code: flunk("hi")
     stacktrace:
       test/elixir/language_test.exs:470: (test)

  .....

  Finished in 0.1 seconds
  22 tests, 1 failure

  Randomized with seed 508535

  """

  @no_failures """
  Finished in 0.1 seconds
  22 tests, 0 failures

  Randomized with seed 463180
  """

  describe "update_mix_test_history_for_file/3" do
    test "removes all failures all tests passed" do
      failures = [
        "test/jazz/jazz_test.exs:99",
        "test/elixir/language_test.exs:10",
        "test/funk/funk_test.exs:10",
        "test/funk/funk_test.exs:20",
        "test/elixir/language_test.exs:24",
        "test/other/other_test.exs:66"
      ]

      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(failures)

      result =
        Language.update_mix_test_history_for_file(
          server_state,
          "test/elixir/language_test.exs",
          @no_failures
        )

      assert %{
               elixir: %{
                 failures: [
                   "test/jazz/jazz_test.exs:99",
                   "test/funk/funk_test.exs:10",
                   "test/funk/funk_test.exs:20",
                   "test/other/other_test.exs:66"
                 ]
               }
             } = result
    end

    test "replaces all failures for file" do
      failures = [
        "test/elixir/language_test.exs:469",
        "test/other/other_test.exs:20",
        "test/elixir/language_test.exs:10",
        "test/other/other_test.exs:10",
        "test/elixir/language_test.exs:20",
        "test/other/other_test.exs:30",
        "test/elixir/language_test.exs:30"
      ]

      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(failures)

      result =
        Language.update_mix_test_history_for_file(
          server_state,
          "test/elixir/language_test.exs",
          @one_failure
        )

      assert %{
               elixir: %{
                 failures: [
                   "test/elixir/language_test.exs:469",
                   "test/other/other_test.exs:20",
                   "test/other/other_test.exs:10",
                   "test/other/other_test.exs:30"
                 ]
               }
             } = result
    end
  end

  @max_failures_1 """
  1) test put_failures_first/2 x (PolyglotWatcher.Elixir.LanguageTest)
  test/elixir/language_test.exs:509

  code: flunk("")
  stacktrace:
    test/elixir/language_test.exs:541: (test)

  --max-failures reached, aborting test suite

  Finished in 0.1 seconds
  1 test, 1 failure

  Randomized with seed 972915
  """

  @max_failures_0 "There are no tests to run"

  describe "put_failures_first/2" do
    test "puts failures in the given mix test output at the top of the failures list" do
      failures = [
        "test/jazz/jazz_test.exs:1",
        "test/elixir/language_test.exs:509",
        "test/jazz/jazz_test.exs:2",
        "test/elixir/language_test.exs:3",
        "test/other/other_test.exs:4"
      ]

      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(failures)

      result = Language.put_failures_first(server_state, @max_failures_1)

      assert %{
               elixir: %{
                 failures: [
                   "test/elixir/language_test.exs:509",
                   "test/elixir/language_test.exs:3",
                   "test/jazz/jazz_test.exs:1",
                   "test/jazz/jazz_test.exs:2",
                   "test/other/other_test.exs:4"
                 ]
               }
             } = result
    end

    test "makes no changes given mix test output with no failing tests" do
      failures = [
        "test/jazz/jazz_test.exs:1",
        "test/elixir/language_test.exs:509",
        "test/jazz/jazz_test.exs:2",
        "test/elixir/language_test.exs:3",
        "test/other/other_test.exs:4"
      ]

      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(failures)

      assert Language.put_failures_first(server_state, @max_failures_0) == server_state
    end
  end
end
