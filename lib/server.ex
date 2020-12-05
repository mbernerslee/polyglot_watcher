defmodule PolyglotWatcher.Server do
  use GenServer
  alias PolyglotWatcher.{Executor, Languages, UserInput, FileSystemChange, Puts}

  @process_name :server

  @default_options [name: @process_name]

  def child_spec do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [@default_options]}
    }
  end

  def start_link(genserver_options \\ @default_options) do
    GenServer.start_link(__MODULE__, [], genserver_options)
  end

  # TODO add a test for let's go
  @impl true
  def init(x) do
    listen_for_user_input()
    {:ok, watcher_pid} = FileSystem.start_link(dirs: ["."])

    FileSystem.subscribe(watcher_pid)

    Puts.put("Let's go...")

    {:ok, %{watcher_pid: watcher_pid, elixir: %{mode: :default, failures: []}}}
  end

  @impl true
  def handle_info({:file_event, _pid, {file_path, [:modified, :closed]}}, state) do
    file_path
    |> FileSystemChange.determine_language_module(state)
    |> Languages.determine_actions()
    |> Executor.run_actions()

    {:noreply, state}
  end

  def handle_info({:file_event, _pid, _}, state) do
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
    unless Mix.env() == :test do
      pid = self()

      spawn_link(fn ->
        user_input = IO.gets("")
        GenServer.call(pid, {:user_input, user_input}, :infinity)
      end)
    end
  end
end
