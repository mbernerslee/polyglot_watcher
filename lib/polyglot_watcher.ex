defmodule PolyglotWatcher do
  use Application
  alias PolyglotWatcher.Server

  def start(_type \\ :normal, _args \\ []) do
    children = [Server.child_spec()]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
