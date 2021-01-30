defmodule PolyglotWatcher.Executor.BlockingTest do
  use GenServer

  @name :blocking_test_executor

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: @name)
  end

  @impl true
  def init(_) do
    {:ok, :blocking}
  end

  @impl true
  def handle_call(:unblock, _from, state) do
    {:reply, :not_blocking, :not_blocking}
  end

  def handle_call(:is_blocking, _from, state) do
    {:reply, state, state}
  end

  def run_actions({actions, server_state}) do
    IO.inspect(actions)
    start_link()
    maybe_block()

    server_state
  end

  def unblock do
    GenServer.call(@name, :unblock)
  end

  defp maybe_block do
    case GenServer.call(@name, :is_blocking) do
      :blocking -> maybe_block()
      :not_blocking -> :not_blocking
    end
  end
end
