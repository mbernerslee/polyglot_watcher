defmodule PolyglotWatcher.ShellCommandRunner do
  use GenServer

  @zombie_killer "#{:code.priv_dir(:polyglot_watcher)}/zombie_killer"
  @exit_code_regex ~r|shell command completed with exit code (?<exit_code>[0-9])|

  def run(command) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, %{command: command, caller_pid: self()})

    receive do
      {:exit, {command_output, exit_code}} -> {command_output, exit_code}
    end
  end

  @impl true
  def init(%{command: command, caller_pid: caller_pid}) do
    port = Port.open({:spawn_executable, @zombie_killer}, args: command)

    {:ok, %{port: port, command_output: "", caller_pid: caller_pid}}
  end

  @impl true
  def handle_info({_port, {:data, command_output}}, state) do
    command_output = to_string(command_output)

    case Regex.named_captures(@exit_code_regex, command_output) do
      nil ->
        IO.write(command_output)
        {:noreply, Map.update!(state, :command_output, &(&1 <> command_output))}

      %{"exit_code" => exit_code} ->
        IO.puts(state.command_output)
        IO.puts(exit_code)
        send(state.caller_pid, {:exit, {state.command_output, String.to_integer(exit_code)}})
        {:stop, :normal, state}
    end
  end

  @impl true
  def terminate(_reason, state) do
    Port.close(state.port)
  end
end
