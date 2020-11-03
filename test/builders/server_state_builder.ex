defmodule PolyglotWatcher.ServerStateBuilder do
  def build do
    %{port: "port", elixir: %{mode: :default, failures: []}}
  end

  def with_elixir_fixed_previous_mode(server_state) do
    put_in(server_state, [:elixir, :mode], :fixed_previous)
  end

  def with_elixir_failures(server_state, failures) do
    put_in(server_state, [:elixir, :failures], failures)
  end
end
