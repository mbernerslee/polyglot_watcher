defmodule PolyglotWatcher.Server do
  use GenServer
  alias PolyglotWatcher.Inotifywait

  @process_name :server

  @default_options [name: @process_name]

  def child_spec do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [@default_options]}
    }
  end

  def get_state(pid \\ @process_name)

  def get_state(name) when is_atom(name) do
    case Process.whereis(name) do
      nil -> :process_not_found
      pid -> get_state(pid)
    end
  end

  def get_state(pid) when is_pid(pid) do
    :sys.get_state(pid)
  end

  def start_link(genserver_options \\ @default_options) do
    GenServer.start_link(__MODULE__, [], genserver_options)
  end

  @impl true
  def init(_) do
    ExUnit.start()

    port = Port.open({:spawn, "inotifywait . -rmqe close_write"}, [:binary])
    Port.connect(port, self())

    {:ok, %{port: port}}
  end

  @impl true
  def handle_info({port, {:data, inotifywait_output}}, state) do
    Inotifywait.run_watcher_actions(inotifywait_output)
    {:noreply, state}
  end
end
