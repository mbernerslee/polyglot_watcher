defmodule PolyglotWatcher.ServerTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias PolyglotWatcher.{Server, ServerStateBuilder}
  alias PolyglotWatcher.Executor.{Test, BlockingTest}
  alias PolyglotWatcher.LanguagesTest
  alias PolyglotWatcher.Languages
  alias PolyglotWatcher.FileSystemChange
  alias PolyglotWatcher.Mocks

  describe "start_link/2" do
    test "with no command line args given, spawns the server process with default starting state" do
      capture_io(fn ->
        assert {:ok, pid} = Server.start_link([], [])
        assert is_pid(pid)

        assert %{watcher_pid: watcher_pid, elixir: elixir} = :sys.get_state(pid)
        assert is_pid(watcher_pid)
        assert %{failures: [], mode: :default} == elixir
      end)
    end

    test "with invalid command line args given, exits" do
      assert {:error, :normal} == Server.start_link(["nonsense"], [])
    end
  end

  describe "child_spec/0" do
    test "returns the default genserver options" do
      assert Server.child_spec() == %{
               id: Server,
               start: {Server, :start_link, [[], [name: :server]]}
             }
    end
  end

  describe "handle_info/2 - file_event" do
    test "regonises file events from FileSystem" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(["test/path/cool_test.exs:2"])

      assert {:noreply, server_state} ==
               Server.handle_info(
                 {:file_event, :pid,
                  {"/home/berners/src/polyglot_watcher/./_build/test/lib/polyglot_watcher/.mix/.mix_test_failures",
                   [:created]}},
                 server_state
               )
    end
  end

  test "actions stack" do
    Application.put_env(:polyglot_watcher, :languages, Mocks.Languages)
    Application.put_env(:polyglot_watcher, :file_system_change, Mocks.FileSystemChange)
    Application.put_env(:polyglot_watcher, :executor, Mocks.BlockingExecutor)

    {:ok, languages_pid} = Mocks.Languages.start_with_action_stack([1, 2, 3, 4, 5])

    {:ok, server_pid} = Server.start_link([], [])
    wait_until_server_responds_to_file_system_changes(server_pid)

    {:ok, _pid} = Mocks.BlockingExecutor.start_link()
    IO.inspect("start link for mock executor")

    # File.touch!("magic_file_system_change_name")
    PolyglotWatcher.ShellCommandRunner.run(["touch", "magic_file_system_change_name"])
    PolyglotWatcher.ShellCommandRunner.run(["touch", "magic_file_system_change_name"])

    Mocks.BlockingExecutor.unblock()

    :sys.get_state(languages_pid)
    |> IO.inspect()

    :sys.get_state(server_pid)
    |> IO.inspect()

    :sys.get_state(languages_pid)
    |> IO.inspect()

    Application.put_env(:polyglot_watcher, :languages, Languages)
    Application.put_env(:polyglot_watcher, :file_system_change, FileSystemChange)
    Application.put_env(:polyglot_watcher, :executor, Test)
  end

  @file_prefix "server_test_outout_"

  test "puts non zero actions to be actioned next" do
    # Application.put_env(:polyglot_watcher, :executor, BlockingTest)
    # {:ok, _pid} = BlockingTest.start_link()
    # BlockingTest.unblock()

    # {:ok, server_pid} = Server.start_link([], [])

    # wait_until_server_responds_to_file_system_changes(server_pid)

    # BlockingTest.block()

    # this_test_file = __ENV__.file()
    # File.touch!(this_test_file)

    # :sys.get_state(server_pid)
    # |> IO.inspect()

    # Application.put_env(:polyglot_watcher, :executor, Test)
  end

  test "ignores file system changes whilst actions from the previous file system change are still running" do
    # Application.put_env(:polyglot_watcher, :executor, BlockingTest)

    # {:ok, _pid} = BlockingTest.start_link()
    # BlockingTest.unblock()

    # Enum.each(1..10, fn number ->
    #  File.touch!("#{@file_prefix}#{number}")
    # end)

    # {:ok, server_pid} = Server.start_link([], [])

    # wait_until_server_responds_to_file_system_changes(server_pid)
    # |> IO.inspect()

    # BlockingTest.block()

    # IO.inspect(self(), label: "test PID (me)")
    # PolyglotWatcher.ShellCommandRunner.run(["touch", "#{@file_prefix}1"])
    # :os.cmd(:"echo 'dude' >> #{@file_prefix}1")
    # inspect_pid_message_box(server_pid)
    # PolyglotWatcher.ShellCommandRunner.run(["touch", "#{@file_prefix}2"])
    # :os.cmd(:"echo 'dude' >> #{@file_prefix}2")
    # inspect_pid_message_box(server_pid)
    # PolyglotWatcher.ShellCommandRunner.run(["touch", "#{@file_prefix}3"])
    # :os.cmd(:"echo 'dude' >> #{@file_prefix}3")
    # inspect_pid_message_box(server_pid)
    # PolyglotWatcher.ShellCommandRunner.run(["touch", "#{@file_prefix}4"])
    # :os.cmd(:"echo 'dude' >> #{@file_prefix}4")
    # PolyglotWatcher.ShellCommandRunner.run(["touch", "#{@file_prefix}5"])
    # :os.cmd(:"echo 'dude' >> #{@file_prefix}5")
    # PolyglotWatcher.ShellCommandRunner.run(["touch", "#{@file_prefix}6"])
    # :os.cmd(:"echo 'dude' >> #{@file_prefix}6")
    # PolyglotWatcher.ShellCommandRunner.run(["touch", "#{@file_prefix}7"])
    # :os.cmd(:"echo 'dude' >> #{@file_prefix}7")
    # PolyglotWatcher.ShellCommandRunner.run(["touch", "#{@file_prefix}8"])
    # :os.cmd(:"echo 'dude' >> #{@file_prefix}8")
    # PolyglotWatcher.ShellCommandRunner.run(["touch", "#{@file_prefix}9"])
    # :os.cmd(:"echo 'dude' >> #{@file_prefix}9")
    # PolyglotWatcher.ShellCommandRunner.run(["touch", "#{@file_prefix}10"])
    # :os.cmd(:"echo 'dude' >> #{@file_prefix}10")

    # BlockingTest.unblock()
    # IO.inspect("UNBLOCK!")
    # BlockingTest.block()

    # PolyglotWatcher.ShellCommandRunner.run(["touch", auto_generated_test_file_path])

    # :timer.sleep(4000)
    # IO.inspect(:sys.get_state(history_pid), limit: :infinity)

    # Process.exit(server_pid, :normal)
    # Application.put_env(:polyglot_watcher, :executor, Test)
  end

  defp wait_until_server_responds_to_file_system_changes(server_pid) do
    PolyglotWatcher.ShellCommandRunner.run(["touch", "server_wait_file"])
    :os.cmd(:"echo 'dude' >> server_wait_file")

    if get_pid_message_box(server_pid) == [] do
      :timer.sleep(10)
      wait_until_server_responds_to_file_system_changes(server_pid)
    end
  end

  defp inspect_pid_message_box(pid) do
    pid
    |> get_pid_message_box()
    |> IO.inspect()
  end

  defp get_pid_message_box(pid) do
    [messages: messages] = :erlang.process_info(pid, [:messages])
    messages
  end

  describe "handle_call/3 - user_input" do
    test "given some unrecognised jank replies with the server_state it was given" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(["test/path/cool_test.exs:2"])

      assert {:noreply, server_state} ==
               Server.handle_call({:user_input, "some jank"}, :from, server_state)
    end

    test "can put it into fix all mode" do
      server_state = ServerStateBuilder.build()

      assert {:noreply, %{elixir: %{mode: {:fix_all, :mix_test}}}} =
               Server.handle_call({:user_input, "ex fa\n"}, :from, server_state)
    end

    test "can put it into fix previous mode" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(["test/path/cool_test.exs:2"])

      assert {:noreply, %{elixir: %{mode: :fixed_previous}}} =
               Server.handle_call({:user_input, "ex f\n"}, :from, server_state)
    end

    test "cannot switch to fix previous mode if no failures" do
      server_state = ServerStateBuilder.build()

      assert {:noreply, %{elixir: %{mode: :default}}} =
               Server.handle_call({:user_input, "ex f\n"}, :from, server_state)
    end

    test "mix test doesn't change the server state" do
      server_state = ServerStateBuilder.build()

      assert {:noreply, %{elixir: %{mode: :default}}} =
               Server.handle_call({:user_input, "ex a\n"}, :from, server_state)
    end

    test "can switch back to default mode" do
      server_state =
        ServerStateBuilder.build()
        |> ServerStateBuilder.with_elixir_failures(["test/path/cool_test.exs:2"])
        |> ServerStateBuilder.with_elixir_fixed_previous_mode()

      assert {:noreply, %{elixir: %{mode: :default}}} =
               Server.handle_call({:user_input, "ex d\n"}, :from, server_state)
    end
  end
end
