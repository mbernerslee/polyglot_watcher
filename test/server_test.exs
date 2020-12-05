defmodule PolyglotWatcher.ServerTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.{Server, ServerStateBuilder}

  describe "start_link/1" do
    test "spawns the server process with default starting state" do
      assert {:ok, pid} = Server.start_link([])
      assert is_pid(pid)

      assert %{watcher_pid: watcher_pid, elixir: elixir} = :sys.get_state(pid)
      assert is_pid(watcher_pid)
      assert %{failures: [], mode: :default} == elixir
    end
  end

  describe "child_spec/0" do
    test "returns the default genserver options" do
      assert Server.child_spec() == %{id: Server, start: {Server, :start_link, [[name: :server]]}}
    end
  end

  describe "handle_info/2 - inotifywait" do
    test "given some unrecognised jank, does nothing" do
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
  end
end
