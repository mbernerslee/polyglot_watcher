defmodule PolyglotWatcher.Elixir.FixAllForFileMode do
  alias PolyglotWatcher.Elixir.{Actions, Language}

  @explanation [
    {:run_sys_cmd, "tput", ["reset"]},
    {:puts, "Switching to fix all for file mode"},
    {:puts, "It'll run: "},
    {:puts,
     "1) 'mix test test/the/path/you/said/file_test.exs' ...if this passes we're good!...otherwise go to 2)"},
    {:puts,
     "2) 'mix test test/the/path/you/said/file_test.exs:23' ...some arbirarily chosen broken test... until it passes, then back to 2)"}
  ]

  @mix_test_pass_exit_code 0

  def enter(server_state) do
    server_state = Language.set_mode(server_state, {:fix_all_for_file, :whole_file})

    {
      %{
        run: @explanation,
        next: %{:fallback => loop(:awaiting_file)}
      },
      server_state
    }
  end

  def actions(server_state, x, file) do
    IO.inspect(server_state)
    test_path = Language.test_path(file.file_path)

    case server_state.elixir.mode do
      {:fix_all_for_file, :awaiting_file} ->
        {
          %{
            run: [
              {:run_elixir_fn, fn -> File.exists?(test_path) end}
            ],
            next: %{
              true => %{
                run: [
                  {:run_sys_cmd, "tput", ["reset"]},
                  {:puts, :green, "Running mix test #{test_path}"},
                  Actions.mix_test(test_path)
                ],
                next: %{
                  @mix_test_pass_exit_code => %{
                    update_server_state:
                      &Language.set_mode(&1, {:fix_all_for_file, :awaiting_file}),
                    run: [
                      {:puts, :green,
                       "Success! all the tests in #{test_path} are currently passing boyo"}
                    ],
                    fallback: :exit
                  },
                  fallback: %{
                    update_server_state:
                      &Language.set_mode(&1, {:fix_all_for_file, test_path, :run_one}),
                    run: Actions.mix_test_head_single(),
                    next: %{fallback: :exit}
                  }
                }
              },
              false => %{
                run: [
                  {:run_sys_cmd, "tput", ["reset"]},
                  {:puts, "No test found at #{test_path}"},
                  {:puts, "Uh-oh, You don't have tests for this do you?"},
                  {:puts, :green, "Awaiting file save..."}
                ]
              }
            }
          },
          server_state
        }
    end
  end

  defp loop(entry_point) do
    %{
      loop_entry_point: entry_point,
      actions: %{
        awaiting_file: %{
          update_server_state: &Language.set_mode(&1, {:fix_all_for_file, :awaiting_file}),
          run: [
            # Actions.mix_test_head_file_quietly()
            {:puts, :green, "Awaiting file save..."}
          ],
          next: %{fallback: :exit}
        }
      }
    }
  end
end
