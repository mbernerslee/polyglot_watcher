defmodule PolyglotWatcher.ShellCommandRunner do
  use GenServer

  def start_link(command) do
    {:ok, pid} =
      GenServer.start_link(__MODULE__, command)
      |> IO.inspect()
  end

  @impl true
  def init(command) do
    {:ok, command}

    port =
      Port.open({:spawn, command}, [])
      # Port.connect(port
      |> IO.inspect()
  end
end
