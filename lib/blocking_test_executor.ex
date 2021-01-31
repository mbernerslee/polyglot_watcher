defmodule PolyglotWatcher.Executor.BlockingTest do
  use GenServer

  @name :blocking_test_executor

  def start_link do
    case GenServer.start_link(__MODULE__, nil, name: @name) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  @impl true
  def init(_) do
    {:ok, :blocking}
  end

  @impl true
  def handle_call(:unblock, _from, state) do
    {:reply, :not_blocking, :not_blocking}
  end

  def handle_call(:block, _from, state) do
    {:reply, :blocking, :blocking}
  end

  def handle_call(:is_blocking, _from, state) do
    {:reply, state, state}
  end

  def run_actions({actions, server_state}) do
    start_link()
    maybe_block()

    server_state
  end

  def unblock do
    GenServer.call(@name, :unblock)
  end

  def block do
    GenServer.call(@name, :block)
  end

  defp maybe_block(first_call \\ true) do
    case GenServer.call(@name, :is_blocking) do
      :blocking ->
        maybe_block(false)

      :not_blocking ->
        :not_blocking
    end
  end
end
