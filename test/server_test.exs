defmodule PolyglotWatcher.ServerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias PolyglotWatcher.{Server, ServerStateBuilder}

  @test_file_path "server_wait_file"

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

    test "starts up into a loading state" do
      assert {:ok, pid} = Server.start_link([], [])
      assert %{warming_up: true} = :sys.get_state(pid)
      # :os.cmd(:"echo 'dude' >> #{@test_file_path}")
      :timer.sleep(1000)
      touch_file_lots()
      # touch_file_lots()
      # :os.cmd(:"echo 'dude' >> server_wait_file")
      IO.inspect(:sys.get_state(pid))
      File.rm(@test_file_path)
    end
  end

  defp touch_file_lots(touches_so_far \\ 1) do
    unless touches_so_far > 20 do
      :timer.sleep(10)
      File.touch!(@test_file_path)
    end
  end

  defp wait_until_server_responds_to_file_system_changes(server_pid) do
    PolyglotWatcher.ShellCommandRunner.run(["touch", "server_wait_file"])
    :os.cmd(:"echo 'dude' >> server_wait_file")

    if get_pid_message_box(server_pid) == [] do
      wait_until_server_responds_to_file_system_changes(server_pid)
    end
  end

  defp get_pid_message_box(pid) do
    [messages: messages] = :erlang.process_info(pid, [:messages])
    messages
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
