defmodule PolyglotWatcher.Server do
  use GenServer
  alias PolyglotWatcher.{Executor, Languages, UserInput, FileSystemChange}

  @process_name :server

  @default_options [name: @process_name]

  @initial_state %{ignore_file_changes: false, warming_up: true}

  @temp_file ".polyglot_watcher_tmp_file"

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
    case UserInput.startup(command_line_args, @initial_state) do
      {:ok, {actions, server_state}} ->
        {:ok, watcher_pid} = FileSystem.start_link(dirs: ["."])
        FileSystem.subscribe(watcher_pid)

        server_state =
          server_state
          |> Map.put(:watcher_pid, watcher_pid)
          |> Map.put(:starting_dir, File.cwd!())

        server_state = Executor.run_actions({actions, server_state})

        wait_for_fs_watch_to_respond_to_file_system()
        listen_for_user_input()
        {:ok, server_state}

      {:error, {actions, server_state}} ->
        Executor.run_actions({actions, server_state})
        {:stop, :normal}
    end
  end

  @impl true
  def hand_info({:file_event, _pid, {file_path, _}}, %{warming_up: true} = state) do
    IO.inspect(file_path)
    {:noreply, state}
  end

  def handle_info({:file_event, _pid, {file_path, [:modified, :closed]}}, state) do
    IO.inspect("I SAW A FILE EVENT!!! #{file_path}")

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

  def handle_call(:warmed_up_yet?, _from, %{warming_up: false} = state) do
    {:reply, true, state}
  end

  def handle_call(:warmed_up_yet?, _from, %{warming_up: false} = state) do
    {:reply, true, %{state | warming_up: }
  end

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

  defp wait_for_fs_watch_to_respond_to_file_system do
    File.touch!(@temp_file)
    pid = self()
    spawn_link(fn -> GenServer.call(pid, :warmed_up_yet?) end)
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
