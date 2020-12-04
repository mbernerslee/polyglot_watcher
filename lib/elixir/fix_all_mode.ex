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
    {:puts,
     "4) 'mix test --failed' ... to see if there're still some broken tests. if yes goto 2)"},
    {:puts,
     "5) 'mix test --failed --max-failures 1' ... to find the next failing test. if there is one goto 2)"},
    {:puts, "6) 'mix test' ... if this passes we're good! (otherwise go back to 2), *waw waw*)"}
  ]

  @mix_test_pass_exit_code 0

  def enter(server_state) do
    server_state = Language.set_mode(server_state, {:fix_all, :mix_test_all})

    {
      %{
        run: explain_and_mix_test(),
        next: %{
          @mix_test_pass_exit_code => all_fixed(),
          :fallback => loop()
        }
      },
      server_state
    }
  end

  defp explain_and_mix_test do
    @explanation ++ [Actions.mix_test()]
  end

  defp loop do
    %{
      loop_entry_point: :single_test,
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
          },
          single_file: %{
            update_server_state: &Language.set_mode(&1, {:fix_all, :single_file}),
            run: [
              {:puts, "Checking if there're any other test failures in that file..."},
              Actions.mix_test_head_file()
            ],
            next: %{
              @mix_test_pass_exit_code => %{
                run: [
                  {:puts, "Fixed all tests in that file!!"}
                ],
                continue: :mix_test
              },
              :fallback => :exit
            }
          },
          mix_test: %{
            update_server_state: &Language.set_mode(&1, {:fix_all, :mix_test}),
            run: [
              {:puts, "Running all tests to find more failures..."},
              Actions.mix_test()
            ],
            next: %{
              @mix_test_pass_exit_code => all_fixed(),
              :fallback => :exit
            }
          }
        }
      }
    }

    # %{
    #  run: [
    #    {:puts, "looks like you've fucked it mate"},
    #    Actions.mix_test_head_single()
    #  ],
    #  next: %{
    #    @mix_test_pass_exit_code => %{
    #      run: [
    #        {:puts, "Nice, you fixed that one, finding the next broken test in that file..."},
    #        Actions.mix_test_head_file()
    #      ]
    #      next: %{
    #        @mix_test_pass_exit_code => %{
    #      }
    #    }
    #  }
    # }
  end

  defp all_fixed do
    %{
      run: [
        {:puts, "Horray!!! All tests passed!"},
        {:puts, "Switching back to default mode"}
      ],
      update_server_state: &Language.set_mode(&1, :default)
    }
  end
end
