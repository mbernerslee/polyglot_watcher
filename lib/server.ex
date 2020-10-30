defmodule PolyglotWatcher.Server do
  use GenServer

  @process_name :server

  @default_options [name: @process_name]

  def child_spec do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [@default_options]}
    }
  end

  def get_state(pid \\ @process_name)
  def get_state(name) when is_atom(name) do
    if Process.whereis(atom) do
      nil -> :process_not_found
      pid -> get_state(pid)
  end

  def get_state(pid) when is_pid(pid) do
    :get_state(pid)
  end

  def start_link(genserver_options \\ @default_options) do
    GenServer.start_link(__MODULE__, [], genserver_options)
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end
end
