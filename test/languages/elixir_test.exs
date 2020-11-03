defmodule PolyglotWatcher.Languages.ElixirTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.Languages.Elixir, as: ElixirLang
  alias PolyglotWatcher.ServerStateBuilder

  @ex ElixirLang.ex()
  @exs ElixirLang.exs()

  describe "determine_actions/2 - default mode" do
    test "finds the equivalent test file" do
      server_state = ServerStateBuilder.build()

      assert {actions, new_server_state} =
               ElixirLang.determine_actions(
                 %{extension: @ex, file_path: "lib/very/cool.ex"},
                 server_state
               )

      assert %{
               next: %{
                 false: %{
                   run: [
                     {:run_sys_cmd, "tput", ["reset"]},
                     {:run_sys_cmd, "echo",
                      ["-e", "\e[35mNo test found at test/very/cool_test.exs\e[39m"]},
                     {:run_sys_cmd, "echo",
                      ["-e", "\e[35mUh-oh, You don't have tests for this do you?\e[39m"]}
                   ]
                 },
                 true: %{
                   run: [
                     {:run_sys_cmd, "tput", ["reset"]},
                     {:run_sys_cmd, "echo",
                      ["-e", "\e[35mRunning mix test test/very/cool_test.exs\e[39m"]},
                     {:mix_test, "test/very/cool_test.exs"}
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
               ElixirLang.determine_actions(
                 %{extension: @ex, file_path: "lib/very/cool.ex"},
                 server_state
               )
    end

    test "given a lib file that doesn't exist, the find file function returns false" do
      server_state = ServerStateBuilder.build()

      assert {actions, new_server_state} =
               ElixirLang.determine_actions(
                 %{extension: @ex, file_path: "lib/very/cool.ex"},
                 server_state
               )

      assert %{run: [run_elixir_fn: fun]} = actions

      assert fun.() == false
    end

    test "given a lib file that realtes to a test that DOES exist, the find file function returns true" do
      server_state = ServerStateBuilder.build()

      assert {actions, new_server_state} =
               ElixirLang.determine_actions(
                 %{extension: @ex, file_path: "lib/languages/elixir.ex"},
                 server_state
               )

      assert %{run: [run_elixir_fn: fun]} = actions

      assert fun.() == true
    end

    test "given a test that DOES exist, the find file function returns true" do
      server_state = ServerStateBuilder.build()

      assert {actions, _new_server_state} =
               ElixirLang.determine_actions(
                 %{extension: @exs, file_path: "test/languages/elixir_test.exs"},
                 server_state
               )

      assert %{run: [run_elixir_fn: fun]} = actions

      assert fun.() == true
    end

    test "given a test that doesn't exist, the find file function returns false" do
      server_state = ServerStateBuilder.build()

      assert {actions, _new_server_state} =
               ElixirLang.determine_actions(
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

      assert {actions, new_server_state} =
               ElixirLang.determine_actions(
                 %{extension: @exs, file_path: "test/nonsense/path/jank_test.exs"},
                 server_state
               )

      assert [
               {:run_sys_cmd, "tput", ["reset"]},
               {:run_sys_cmd, "echo",
                ["-e", "\e[35mRunning 'mix test test/languages/elixir_test.exs:103'\e[39m"]},
               {:mix_test, "test/languages/elixir_test.exs:103"},
               {:run_sys_cmd, "echo",
                ["-e", "\e[35mI've been told to ONLY run this one FIXED path btw!\e[39m"]},
               {:run_sys_cmd, "echo",
                ["-e", "\e[35mRetern to default mode by entering 'ex d'\e[39m"]}
             ] = actions
    end

    test "returns the default mode options if there is no test in the failures list" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_fixed_previous_mode()
        |> ServerStateBuilder.with_elixir_failures([])

      assert {actions, new_server_state} =
               ElixirLang.determine_actions(
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

      assert {actions, new_server_state} =
               ElixirLang.determine_actions(
                 %{extension: @exs, file_path: "test/nonsense/path/jank_test.exs"},
                 server_state
               )

      assert [
               {:run_sys_cmd, "tput", ["reset"]},
               {:run_sys_cmd, "echo",
                ["-e", "\e[35mRunning 'mix test test/languages/elixir_test.exs:103'\e[39m"]},
               {:mix_test, "test/languages/elixir_test.exs:103"},
               {:run_sys_cmd, "echo",
                ["-e", "\e[35mI've been told to ONLY run this one FIXED path btw!\e[39m"]},
               {:run_sys_cmd, "echo",
                ["-e", "\e[35mRetern to default mode by entering 'ex d'\e[39m"]}
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

      result = ElixirLang.add_mix_test_history(server_state, test_output)
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
             } = ElixirLang.add_mix_test_history(server_state, test_output)
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

      result = ElixirLang.reset_mix_test_history(server_state, test_output)
      assert %{elixir: %{failures: ["test/languages/elixir_test.exs:154"]}} = result
    end
  end
end
