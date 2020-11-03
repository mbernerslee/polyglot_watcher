defmodule PolyglotWatcher.Executor.RealTest do
  require Logger
  import ExUnit.CaptureLog
  import ExUnit.CaptureIO
  use ExUnit.Case, async: true

  alias PolyglotWatcher.Executor.Real
  alias PolyglotWatcher.ServerStateBuilder

  describe "run_actions/2 - can run different actions" do
    test "can run given elixir functions" do
      server_state = ServerStateBuilder.build()

      assert capture_log(fn ->
               Real.run_actions(
                 {[{:run_elixir_fn, fn -> Logger.debug("hello mother") end}], server_state}
               )
             end) =~ "hello mother"
    end

    test "can run arbitrary system commands" do
      server_state = ServerStateBuilder.build()

      assert capture_io(fn ->
               Real.run_actions({[{:run_sys_cmd, "echo", ["hello dave"]}], server_state})
             end) =~ "hello dave"
    end

    test "can run mix test" do
      server_state = ServerStateBuilder.build()

      mix_test_output =
        capture_io(fn ->
          Real.run_actions({[{:mix_test, "test/example_test.exs"}], server_state})
        end)

      assert mix_test_output =~ "0 failures"
      assert mix_test_output =~ "1 test"
    end

    # test "can run mix test (all tests)" do
    #  server_state = ServerStateBuilder.build()

    #  mix_test_output =
    #    capture_io(fn ->
    #      Real.run_actions({[:mix_test], server_state})
    #    end)

    #  assert mix_test_output =~ "0 failures"
    # end
  end

  describe "run_actions/2 - with a map" do
    test "runs the right thing given a branching map of actions" do
      server_state = ServerStateBuilder.build()

      actions = %{
        next: %{
          false: %{
            run: [
              {:run_sys_cmd, "echo", ["-e", "will not echo false thing"]}
            ]
          },
          true: %{
            run: [
              {:run_sys_cmd, "echo", ["WILL echo true thing!"]}
            ]
          }
        },
        run: [
          run_elixir_fn: fn -> true end
        ]
      }

      io = capture_io(fn -> Real.run_actions({actions, server_state}) end)

      assert io =~ "WILL echo true thing!"
      refute io =~ "will not echo false thing"
    end

    test "runs the right thing given a larger branching map of actions" do
      server_state = ServerStateBuilder.build()

      actions = %{
        next: %{
          false: %{
            run: [{:run_sys_cmd, "echo", ["-e", "will not echo false thing"]}]
          },
          true: %{
            run: [
              {:run_sys_cmd, "echo", ["-e", "I WILL echo true thing"]},
              {:run_elixir_fn, fn -> 1 end}
            ],
            next: %{
              1 => %{
                run: [
                  {:run_sys_cmd, "echo", ["-e", "I hit 1!"]},
                  {:run_elixir_fn, fn -> 3 end}
                ],
                next: %{
                  3 => %{
                    run: [{:run_sys_cmd, "echo", ["-e", "I hit 3!"]}]
                  },
                  4 => %{
                    run: [{:run_sys_cmd, "echo", ["-e", "I hit 4!"]}]
                  }
                }
              },
              2 => %{run: [{:run_sys_cmd, "echo", ["-e", "I hit 2!"]}]}
            }
          }
        },
        run: [run_elixir_fn: fn -> true end]
      }

      io = capture_io(fn -> Real.run_actions({actions, server_state}) end)

      assert io == "I WILL echo true thing\nI hit 1!\nI hit 3!\n"
    end
  end
end
