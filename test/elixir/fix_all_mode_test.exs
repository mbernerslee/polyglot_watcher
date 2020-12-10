defmodule PolyglotWatcher.Elixir.FixAllModeTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.Elixir.{Actions, FixAllMode}
  alias PolyglotWatcher.ServerStateBuilder

  describe "enter/1" do
    test "given a server_state, sets the elixir mode to fix_all mix_test" do
      server_state = ServerStateBuilder.build()

      {_actions, server_state} = FixAllMode.enter(server_state)

      assert %{elixir: %{mode: {:fix_all, :mix_test}}} = server_state
    end

    test "given a server_state, displays the explanation and puts the 'loop' actions" do
      server_state = ServerStateBuilder.build()

      {actions, _server_state} = FixAllMode.enter(server_state)

      assert %{
               run: explanation,
               next: %{fallback: loop}
             } = actions

      assert explanation == [
               {:puts, "Switching to fix all mode"},
               {:puts, "It'll run: "},
               {:puts, "1) 'mix test' ...if this passes we're good!...otherwise go to 2)"},
               {:puts,
                "2) 'mix test /path/to/specific/failure_test.exs:23' ...some arbirarily chosen broken test... until it passes"},
               {:puts,
                "3) 'mix test /path/to/specific/failure_test.exs' ...to see if there're still some broken tests in this file. if so go back to 2)"},
               {:puts,
                "4) 'mix test --failed --max-failures 1'... if any test fails then go back to 2) with that test failure, otherwise go to 1)"}
             ]

      assert_is_loop(loop, :mix_test)
    end
  end

  describe "actions/2" do
    test "given different entry points, puts 'loop' actions with different entry points" do
      server_state = ServerStateBuilder.build()

      assert {%{next: %{fallback: loop}}, ^server_state} =
               FixAllMode.actions(server_state, :single_test)

      assert_is_loop(loop, :single_test)

      assert {%{next: %{fallback: loop}}, ^server_state} =
               FixAllMode.actions(server_state, :single_file)

      assert_is_loop(loop, :single_file)

      assert {%{next: %{fallback: loop}}, ^server_state} =
               FixAllMode.actions(server_state, :mix_test)

      assert_is_loop(loop, :mix_test)
    end

    test "always clears the screen first" do
      server_state = ServerStateBuilder.build()

      assert {%{run: actions}, _} = FixAllMode.actions(server_state, :single_test)

      assert actions == [{:run_sys_cmd, "tput", ["reset"]}]
    end

    test "raises given a bad entry point" do
      server_state = ServerStateBuilder.build()

      msg = "Unrecognised entry_point 'nonsense'"

      assert_raise RuntimeError, msg, fn -> FixAllMode.actions(server_state, :nonsense) end
      # flunk("")
    end
  end

  defp assert_is_loop(loop, entry_point) do
    assert %{
             loop_entry_point: ^entry_point,
             actions: %{
               single_test: %{
                 update_server_state: single_test_update_fun,
                 run: [
                   single_test_action
                 ],
                 next: %{
                   0 => %{
                     run: [],
                     continue: :single_file
                   },
                   :fallback => :exit
                 }
               },
               single_file: %{
                 update_server_state: single_file_update_fun,
                 run: [
                   # {:write, "\n\r"},
                   # {:write, "Checking if there're any other test failures in that file    "},
                   single_file_action
                 ],
                 next: %{
                   0 => %{
                     run: [],
                     continue: :mix_test_failed_one
                   },
                   :fallback => %{
                     continue: :single_test,
                     run: [{:puts, :red, "At least one failing test remains I'm afraid"}]
                   }
                 }
               },
               mix_test_failed_one: %{
                 update_server_state: failed_one_updater,
                 run: [
                   mix_test_failed_one_action
                 ],
                 next: %{
                   0 => %{
                     run: [],
                     continue: :mix_test
                   },
                   :fallback => %{
                     run: [
                       # {:puts, :red, "At least one failing test remains I'm afraid"}
                     ],
                     continue: :single_test
                   }
                 }
               },
               mix_test: %{
                 update_server_state: mix_test_update_fun,
                 run: [
                   # {:puts, ""},
                   # {:write, "Running all tests    "},
                   mix_test_action
                 ],
                 next: %{
                   0 => %{run: []},
                   :fallback => %{
                     run: [],
                     continue: :single_test
                   }
                 }
               }
             }
           } = loop

    default_server_state = ServerStateBuilder.build()

    assert %{elixir: %{mode: {:fix_all, :single_test}}} =
             single_test_update_fun.(default_server_state)

    assert single_test_action == Actions.mix_test_head_single()

    assert %{elixir: %{mode: {:fix_all, :mix_test_failed_one}}} =
             failed_one_updater.(default_server_state)

    assert mix_test_failed_one_action == Actions.mix_test_failed_one()

    assert %{elixir: %{mode: {:fix_all, :single_file}}} =
             single_file_update_fun.(default_server_state)

    assert single_file_action == Actions.mix_test_head_file_quietly()

    assert %{elixir: %{mode: {:fix_all, :mix_test}}} = mix_test_update_fun.(default_server_state)

    assert mix_test_action == Actions.mix_test_quietly()
  end
end
