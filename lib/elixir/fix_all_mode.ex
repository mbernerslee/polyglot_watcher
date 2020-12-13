defmodule PolyglotWatcher.Elixir.FixAllMode do
  alias PolyglotWatcher.Elixir.{Actions, Language}

  @explanation [
    {:run_sys_cmd, "tput", ["reset"]},
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

  @mix_test_pass_exit_code 0

  @entry_points [:single_test, :single_file, :mix_test]

  def enter(server_state) do
    server_state = Language.set_mode(server_state, {:fix_all, :mix_test})

    {
      %{
        run: @explanation,
        next: %{:fallback => loop(:mix_test)}
      },
      server_state
    }
  end

  def actions(server_state, entry_point) when entry_point in @entry_points do
    {%{run: [{:run_sys_cmd, "tput", ["reset"]}], next: %{:fallback => loop(entry_point)}},
     server_state}
  end

  def actions(_server_state, entry_point) do
    raise "Unrecognised entry_point '#{entry_point}'"
  end

  defp loop(entry_point) do
    %{
      loop_entry_point: entry_point,
      actions: %{
        single_test: %{
          update_server_state: &Language.set_mode(&1, {:fix_all, :single_test}),
          run: [
            Actions.mix_test_head_single()
          ],
          next: %{
            @mix_test_pass_exit_code => %{
              run: [],
              continue: :single_file
            },
            :fallback => :exit
          }
        },
        single_file: %{
          update_server_state: &Language.set_mode(&1, {:fix_all, :single_file}),
          run: [
            Actions.mix_test_head_file_quietly()
          ],
          next: %{
            @mix_test_pass_exit_code => %{
              run: [],
              continue: :mix_test_failed_one
            },
            :fallback => %{
              run: [
                {:puts, :red, "At least one failing test remains I'm afraid"}
              ],
              continue: :single_test
            }
          }
        },
        mix_test_failed_one: %{
          update_server_state: &Language.set_mode(&1, {:fix_all, :mix_test_failed_one}),
          run: [
            Actions.mix_test_failed_one()
          ],
          next: %{
            @mix_test_pass_exit_code => %{
              run: [],
              continue: :mix_test
            },
            :fallback => %{
              run: [],
              continue: :single_test
            }
          }
        },
        mix_test: %{
          update_server_state: &Language.set_mode(&1, {:fix_all, :mix_test}),
          run: [
            Actions.mix_test_quietly()
          ],
          next: all_fixed()
        }
      }
    }
  end

  defp all_fixed do
    %{
      @mix_test_pass_exit_code => %{
        run: []
      },
      :fallback => %{
        run: [],
        continue: :single_test
      }
    }
  end
end
