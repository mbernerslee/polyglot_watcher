defmodule PolyglotWatcher.UserInputTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.ServerStateBuilder
  alias PolyglotWatcher.UserInput

  # TODO move the elixir specific stuff to its own module. make an abstraction for language agnostic user input parsing

  describe "determine_actions/2" do
    test "shows the usage instructions given jank" do
      server_state = ServerStateBuilder.build()

      assert {actions, ^server_state} = UserInput.determine_actions("asdsa", server_state)
      assert [{:run_sys_cmd, "echo", ["-e", usage_instructions]}] = actions

      assert Regex.match?(
               ~r|ex f.*fixed mode: only run the most recently run test that failed \(when elixir files are saved\)|,
               usage_instructions
             )
    end
  end

  describe "determine_actions/2 - fixed_previous mode" do
    test "entering fixed previous mode" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(["test/path_test.exs:10"])

      assert {actions, new_server_state} = UserInput.determine_actions("ex f\n", server_state)

      [
        {:run_sys_cmd, "echo", ["-e", first_echo]},
        {:run_sys_cmd, "echo", ["-e", second_echo]},
        {:run_sys_cmd, "echo", ["-e", third_echo]},
        {:mix_test, "test/path_test.exs:10"}
      ] = actions

      assert first_echo =~ "Switching to fixed mode"
      assert second_echo =~ "Will only run 'mix test test/path_test.exs:10' unless told otherwise"
      assert third_echo =~ "Return to default mode by entering 'ex d'"

      assert %{elixir: %{mode: :fixed_previous}} = new_server_state
    end

    test "refuses to switch mode of failures list is empty" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures([])

      assert {actions, new_server_state} = UserInput.determine_actions("ex f\n", server_state)

      [
        {:run_sys_cmd, "echo", ["-e", first_echo]},
        {:run_sys_cmd, "echo", ["-e", second_echo]}
      ] = actions

      assert first_echo =~
               "Cannot switch to fixed mode because my memory of failing tests is empty"

      assert second_echo =~ "so I don't know which test you want me to run..."

      assert %{elixir: %{mode: :default}} = new_server_state
    end
  end

  describe "determine_actions/2 - fixed_file mode" do
    test "entering fixed file mode" do
      server_state = ServerStateBuilder.build()

      assert {actions, new_server_state} =
               UserInput.determine_actions("ex test/example_test.exs:9\n", server_state)

      [
        {:run_sys_cmd, "echo", ["-e", first_echo]},
        {:run_sys_cmd, "echo", ["-e", second_echo]},
        {:run_sys_cmd, "echo", ["-e", third_echo]},
        {:mix_test, "test/example_test.exs:9"}
      ] = actions

      assert first_echo =~ "Switching to fixed file mode"

      assert second_echo =~
               "I'll only run 'mix test test/example_test.exs:9' unless told otherwise"

      assert third_echo =~ "Return to default mode by entering 'ex d'"

      assert %{elixir: %{mode: {:fixed_file, "test/example_test.exs:9"}}} = new_server_state
    end

    test "stays in previous mode given janky user_input & returns the usage instructions" do
      server_state = ServerStateBuilder.build()

      assert {actions, new_server_state} =
               UserInput.determine_actions("ex total_jank\n", server_state)

      assert [{:run_sys_cmd, "echo", ["-e", _usage_instructions]}] = actions

      assert %{elixir: %{mode: :default}} = new_server_state
    end
  end

  describe "determine_actions - default mode" do
    test "can reenter it" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_fixed_previous_mode()

      assert {actions, new_server_state} = UserInput.determine_actions("ex d\n", server_state)

      [{:run_sys_cmd, "echo", ["-e", echo]}] = actions

      assert echo =~ "Switching back to default mode"

      assert %{elixir: %{mode: :default}} = new_server_state
    end
  end

  describe "determine_actions - run all tests" do
    test "can reenter it" do
      server_state = ServerStateBuilder.build()

      assert {actions, new_server_state} = UserInput.determine_actions("ex a\n", server_state)

      [
        {:run_sys_cmd, "echo", ["-e", echo]},
        :mix_test
      ] = actions

      assert echo =~ "Running 'mix test'"

      assert %{elixir: %{mode: :default}} = new_server_state
    end
  end
end
