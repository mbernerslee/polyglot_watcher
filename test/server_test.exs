defmodule PolyglotWatcher.ServerTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.Server

  describe "start_link/1" do
    test "spawns the server process with default starting state" do
      assert {:ok, pid} = Server.start_link([])
      assert is_pid(pid)

      assert %{port: _, elixir: elixir} = :sys.get_state(pid)
      assert %{failures: [], mode: :default} == elixir
    end

    test "spawns the server process with a port to inotifywait" do
      assert {:ok, pid} = Server.start_link([])

      assert %{port: port} = :sys.get_state(pid)
      port_info = Port.info(port)
      assert port_info[:connected] == pid
      assert port_info[:links] == [pid]
      assert to_string(port_info[:name]) =~ "priv/zombie_killer inotifywait . -rmqe close_write"
    end
  end

  describe "child_spec/0" do
    test "returns the default genserver options" do
      assert Server.child_spec() == %{id: Server, start: {Server, :start_link, [[name: :server]]}}
    end
  end

  describe "handle_info/2 - inotifywait" do
    test "given some unrecognised jank, does nothing" do
      server_state = %{
        port: "port",
        elixir: %{mode: :default, failures: ["test/path/cool_test.exs:2"]}
      }

      assert {:noreply, server_state} ==
               Server.handle_info({:port, {:data, "some jank"}}, server_state)
    end
  end

  describe "handle_call/3 - user_input" do
    test "given some unrecognised jank replies with the server_state it was given" do
      server_state = %{
        port: "port",
        elixir: %{mode: :default, failures: ["test/path/cool_test.exs:2"]}
      }

      assert {:noreply, server_state} ==
               Server.handle_call({:user_input, "some jank"}, :from, server_state)
    end
  end
end
