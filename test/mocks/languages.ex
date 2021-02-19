defmodule PolyglotWatcher.Mocks.Languages do
  use GenServer

  @name :languages_test

  def start_with_action_stack(actions_stack) do
    GenServer.start_link(__MODULE__, actions_stack, name: @name)
  end

  @impl true
  def init(actions_stack) do
    {:ok, actions_stack}
  end

  @impl true
  def handle_call(:pop_action, _from, []) do
    {:reply, :action_stack_empty, []}
  end

  def handle_call(:pop_action, _from, [action | rest]) do
    {:reply, action, rest}
  end

  def determine_actions({:noop, server_state}) do
    IO.inspect("Called Mocks.Languages determine_actions with :noop")
    {[], server_state}
  end

  def determine_actions({_, _, server_state}) do
    IO.inspect("called determine_actions")
    {[GenServer.call(@name, :pop_action)], server_state}
  end
end
