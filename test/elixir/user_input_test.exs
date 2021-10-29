defmodule PolyglotWatcher.Elixir.UserInputTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.ServerStateBuilder
  alias PolyglotWatcher.Elixir.Actions
  alias PolyglotWatcher.Elixir.UserInput

  describe "determine_actions/2 - fix all mode" do
    test "can change the server state to fix all mode" do
      server_state = ServerStateBuilder.build()

      assert {:ok, {actions, server_state}} = UserInput.determine_actions("ex fa\n", server_state)

      assert %{elixir: %{mode: {:fix_all, :mix_test}}} = server_state

      assert %{
               run: _,
               next: %{
                 fallback: %{
                   loop_entry_point: :mix_test
                 }
               }
             } = actions
    end
  end

  describe "determine_actions - default mode" do
    test "can reenter it" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_fixed_previous_mode()

      assert {:ok, {actions, new_server_state}} =
               UserInput.determine_actions("ex d\n", server_state)

      [{:run_sys_cmd, "tput", ["reset"]}, {:puts, echo}] = actions

      assert echo =~ "Switching to default mode"

      assert %{elixir: %{mode: :default}} = new_server_state
    end
  end

  describe "determine_actions - run all tests" do
    test "can reenter it" do
      server_state = ServerStateBuilder.build()

      assert {:ok, {actions, new_server_state}} =
               UserInput.determine_actions("ex a\n", server_state)

      [{:puts, echo}, {:module_action, _, :mix_test}] = actions

      assert echo =~ "Running 'mix test'"

      assert %{elixir: %{mode: :default}} = new_server_state
    end
  end

  describe "determine_actions/2 - fixed_file mode" do
    test "entering fixed file mode" do
      server_state = ServerStateBuilder.build()

      assert {:ok, {actions, new_server_state}} =
               UserInput.determine_actions("ex test/example_test.exs:9\n", server_state)

      [
        {:run_sys_cmd, "tput", ["reset"]},
        {:puts, first_echo},
        {:puts, second_echo},
        {:puts, third_echo},
        mix_test
      ] = actions

      assert Actions.mix_test("test/example_test.exs:9") == mix_test

      assert first_echo =~ "Switching to fixed mode"

      assert second_echo =~
               "I'll only run 'mix test test/example_test.exs:9' unless told otherwise"

      assert third_echo =~ "Return to default mode by entering 'ex d'"

      assert %{elixir: %{mode: {:fixed_file, "test/example_test.exs:9"}}} = new_server_state
    end

    test "given nonsense but with the prefix, returns no actions" do
      server_state = ServerStateBuilder.build()

      assert :no_actions == UserInput.determine_actions("ex total_jank\n", server_state)
    end
  end

  describe "determine_actions/2 - fixed_previous mode" do
    test "entering fixed previous mode" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(["test/path_test.exs:10"])

      assert {:ok, {actions, new_server_state}} =
               UserInput.determine_actions("ex f\n", server_state)

      [
        {:run_sys_cmd, "tput", ["reset"]},
        {:puts, first_echo},
        {:puts, second_echo},
        {:puts, third_echo},
        {:module_action, _, {:mix_test, "test/path_test.exs:10"}}
      ] = actions

      assert first_echo =~ "Switching to fixed mode"
      assert second_echo =~ "I'll only run 'mix test test/path_test.exs:10' unless told otherwise"
      assert third_echo =~ "Return to default mode by entering 'ex d'"

      assert %{elixir: %{mode: :fixed_previous}} = new_server_state
    end

    test "refuses to switch mode of failures list is empty" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures([])

      assert {:ok, {actions, new_server_state}} =
               UserInput.determine_actions("ex f\n", server_state)

      [
        {:puts, :red, first_echo},
        {:puts, :red, second_echo}
      ] = actions

      assert first_echo =~
               "Cannot switch to fixed mode because my memory of failing tests is empty"

      assert second_echo =~ "so I don't know which test you want me to run..."

      assert %{elixir: %{mode: :default}} = new_server_state
    end
  end

  describe "determine_actions/2 - fix_all_in_file mode" do
    test "entering the mode" do
      server_state = ServerStateBuilder.build()

      assert {:ok, {actions, new_server_state}} =
               UserInput.determine_actions("ex faff\n", server_state)

      assert %{elixir: %{mode: {:fix_all_for_file, :whole_file}}} = new_server_state

      assert %{run: _, next: %{fallback: _}} = actions
    end
  end
end
