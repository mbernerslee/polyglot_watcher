defmodule PolyglotWatcher.ServerStateBuilder do
  def build do
    %{watcher_pid: :watcher_pid, elixir: %{mode: :default, failures: []}}
  end

  def without_watcher_pid(server_state) do
    Map.delete(server_state, :watcher_pid)
  end

  def with_elixir_fixed_previous_mode(server_state) do
    put_in(server_state, [:elixir, :mode], :fixed_previous)
  end

  def with_elixir_fixed_file_mode(server_state, file_path) do
    put_in(server_state, [:elixir, :mode], {:fixed_file, file_path})
  end

  def with_elixir_fix_all_mode(server_state, fix_all) do
    put_in(server_state, [:elixir, :mode], {:fix_all, fix_all})
  end

  def with_elixir_default_mode(server_state) do
    put_in(server_state, [:elixir, :mode], :default)
  end

  def with_elixir_failures(server_state, failures) do
    put_in(server_state, [:elixir, :failures], failures)
  end
end
