defmodule PolyglotWatcher.Server do
  use GenServer
  alias PolyglotWatcher.{Executor, UserInput, Inotifywait}

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
    port = Port.open({:spawn, run_inotifywait_command()}, [:binary])

    Port.connect(port, self())
    listen_for_user_input()

    {:ok, %{port: port, elixir: %{mode: :default, failures: []}}}
  end

  defp run_inotifywait_command do
    "#{Path.join(:code.priv_dir(:polyglot_watcher), "zombie_killer")} inotifywait . -rmqe close_write"
  end

  @impl true
  def handle_info({_port, {:data, inotifywait_output}}, state) do
    state =
      inotifywait_output
      |> Inotifywait.determine_actions(state)
      |> Executor.run_actions()

    {:noreply, state}
  end

  @impl true
  def handle_call({:user_input, user_input}, _from, state) do
    state =
      user_input
      |> UserInput.determine_actions(state)
      |> Executor.run_actions()

    listen_for_user_input()
    {:noreply, state}
  end

  defp listen_for_user_input do
    pid = self()

    spawn_link(fn ->
      user_input = IO.gets("")
      GenServer.call(pid, {:user_input, user_input}, :infinity)
    end)
  end
end
