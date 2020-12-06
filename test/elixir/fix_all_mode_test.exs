defmodule PolyglotWatcher.Elixir.FixAllModeTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.Elixir.{Actions, FixAllMode}
  alias PolyglotWatcher.ServerStateBuilder

  describe "enter/1" do
    test "given a server_state, sets the elixir mode to fix_all mix_test" do
      server_state = ServerStateBuilder.build()

      {_actions, server_state} = FixAllMode.enter(server_state)

      assert %{elixir: %{mode: {:fix_all, :mix_test}}} = server_state
      # flunk("oopsy")
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
               {:puts, "1) 'mix test' to see how bad it is.."},
               {:puts,
                "2) 'mix test /path/to/specific/failure_test.exs:23' ... some arbirarily chosen broken test...until it pases"},
               {:puts,
                "3) 'mix test /path/to/specific/failure_test.exs' ... to see if there're still some broken tests. if yes goto 2)"},
               {:puts,
                "4) 'mix test' ... if this passes we're good! (otherwise go back to 2), *waw waw*)"}
             ]

      assert_is_loop(loop, :mix_test)
    end
  end

  describe "actions/2" do
    test "given different entry points, puts 'loop' actions with different entry points" do
      server_state = ServerStateBuilder.build()

      assert {%{run: [], next: %{fallback: loop}}, ^server_state} =
               FixAllMode.actions(server_state, :single_test)

      assert_is_loop(loop, :single_test)

      assert {%{run: [], next: %{fallback: loop}}, ^server_state} =
               FixAllMode.actions(server_state, :single_file)

      assert_is_loop(loop, :single_file)

      assert {%{run: [], next: %{fallback: loop}}, ^server_state} =
               FixAllMode.actions(server_state, :mix_test)

      assert_is_loop(loop, :mix_test)
    end

    test "raises given a bad entry point" do
      server_state = ServerStateBuilder.build()

      msg = "Unrecognised entry_point 'nonsense'"

      assert_raise RuntimeError, msg, fn -> FixAllMode.actions(server_state, :nonsense) end
    end
  end

  defp assert_is_loop(loop, entry_point) do
    assert %{
             loop_entry_point: ^entry_point,
             actions: %{
               single_test: %{
                 update_server_state: single_test_update_fun,
                 run: [
                   {:puts, "Running a single test until it passes..."},
                   single_test_action
                 ],
                 next: %{
                   0 => %{
                     run: [
                       {:puts, "Fixed it!"}
                     ],
                     continue: :single_file
                   },
                   :fallback => :exit
                 }
               },
               single_file: %{
                 update_server_state: single_file_update_fun,
                 run: [
                   {:puts, "Checking if there're any other test failures in that file..."},
                   single_file_action
                 ],
                 next: %{
                   0 => %{
                     run: [
                       {:puts, "Fixed all tests in that file!!"}
                     ],
                     continue: :mix_test
                   },
                   :fallback => :exit
                 }
               },
               mix_test: %{
                 update_server_state: mix_test_update_fun,
                 run: [
                   {:puts, "Running all tests..."},
                   mix_test_action
                 ],
                 next: %{
                   0 => _,
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

    assert %{elixir: %{mode: {:fix_all, :single_file}}} =
             single_file_update_fun.(default_server_state)

    assert single_file_action == Actions.mix_test_head_file()

    assert %{elixir: %{mode: {:fix_all, :mix_test}}} = mix_test_update_fun.(default_server_state)

    assert mix_test_action == Actions.mix_test()
  end
end
