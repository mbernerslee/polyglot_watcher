defmodule PolyglotWatcher.Elixir.FixAllMode do
  alias PolyglotWatcher.Elixir.{Actions, Language}

  @explanation [
    {:puts, "Switching to fix all mode"},
    {:puts, "It'll run: "},
    {:puts, "1) 'mix test' to see how bad it is.."},
    {:puts,
     "2) 'mix test /path/to/specific/failure_test.exs:23' ... some arbirarily chosen broken test...until it pases"},
    {:puts,
     "3) 'mix test /path/to/specific/failure_test.exs' ... to see if there're still some broken tests. if yes goto 2)"},
    {:puts, "4) 'mix test' ... if this passes we're good! (otherwise go back to 2), *waw waw*)"}
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
    {%{run: [], next: %{:fallback => loop(entry_point)}}, server_state}
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
            {:puts, "Running a single test until it passes..."},
            Actions.mix_test_head_single()
          ],
          next: %{
            @mix_test_pass_exit_code => %{
              run: [
                {:puts, "Fixed it!"}
              ],
              continue: :single_file
            },
            :fallback => :exit
          }
        },
        single_file: %{
          update_server_state: &Language.set_mode(&1, {:fix_all, :single_file}),
          run: [
            {:puts, "Checking if there're any other test failures in that file..."},
            Actions.mix_test_head_file_quietly()
          ],
          next: %{
            @mix_test_pass_exit_code => %{
              run: [
                {:puts, :green, "Fixed all tests in that file!!"}
              ],
              continue: :mix_test
            },
            :fallback => :exit
          }
        },
        mix_test: %{
          update_server_state: &Language.set_mode(&1, {:fix_all, :mix_test}),
          run: [
            {:puts, "Running all tests..."},
            Actions.mix_test_quietly()
          ],
          next: %{
            @mix_test_pass_exit_code => all_fixed(),
            :fallback => %{
              run: [],
              continue: :single_test
            }
          }
        }
      }
    }
  end

  # TODO add randomized insults on test failure
  # TODO add randomized sarcastic praise on success
  # TODO add an extra mix test --failed --max 1, to speed it up for when its really broken
  # TODO add tput reset in the loop (and maybe other places?)
  # TODO add some logging to say how many tests were fixed (or broken?)
  # TODO wire in .mix test failures, instead of keeping track of failing tests ourselves
  defp all_fixed do
    %{
      run: [
        {:puts, :green, "*****************************************************"},
        {:puts, :green, "All tests passed!"},
        {:puts, :green, "Against all odds, you did it. Incredible. Have a cookie"},
        {:puts, :green, "*****************************************************"},
        {:puts, "Switching back to default mode"}
      ],
      update_server_state: &Language.set_mode(&1, :default)
    }
  end
end
