defmodule PolyglotWatcher.Server do
  use GenServer
  alias PolyglotWatcher.{Executor, Languages, UserInput, FileSystemChange, Puts}

  @process_name :server

  @default_options [name: @process_name]

  @initial_state %{
    ignore_file_changes: false,
    elixir: %{mode: :default, failures: []}
  }

  def child_spec(command_line_args \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [command_line_args, @default_options]}
    }
  end

  def start_link(command_line_args \\ [], genserver_options \\ @default_options) do
    GenServer.start_link(__MODULE__, command_line_args, genserver_options)
  end

  @impl true
  def init(command_line_args) do
    case UserInput.determine_startup_actions(command_line_args, @initial_state) do
      {:ok, {actions, server_state}} ->
        {:ok, watcher_pid} = FileSystem.start_link(dirs: ["."])
        FileSystem.subscribe(watcher_pid)
        Puts.on_new_line(UserInput.usage())

        server_state =
          Executor.run_actions({actions, server_state})
          |> IO.inspect()

        listen_for_user_input()

        {:ok, Map.put(server_state, :watcher_pid, watcher_pid)}

      {:error, {actions, server_state}} ->
        Executor.run_actions({actions, server_state})
        :ignore
    end
  end

  @impl true
  def handle_info({:file_event, _pid, {file_path, [:modified, :closed]}}, state) do
    if state.ignore_file_changes do
      {:noreply, state}
    else
      set_ignore_file_changes(true)

      state =
        file_path
        |> FileSystemChange.determine_language_module(state)
        |> Languages.determine_actions()
        |> Executor.run_actions()

      set_ignore_file_changes(false)

      {:noreply, state}
    end
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

  @impl true
  def handle_cast({:ignore_file_changes, bool}, state) do
    {:noreply, %{state | ignore_file_changes: bool}}
  end

  defp set_ignore_file_changes(true_or_false) do
    pid = self()
    spawn_link(fn -> GenServer.cast(pid, {:ignore_file_changes, true_or_false}) end)
  end

  defp listen_for_user_input do
    if should_listen_for_user_input?() do
      pid = self()

      spawn_link(fn ->
        user_input = IO.gets("")
        GenServer.call(pid, {:user_input, user_input}, :infinity)
      end)
    end
  end

  defp should_listen_for_user_input? do
    Application.get_env(:polyglot_watcher, :listen_for_user_input, true)
  end
end
