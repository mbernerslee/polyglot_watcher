defmodule PolyglotWatcherTest do
  use ExUnit.Case
  doctest PolyglotWatcher

  test "greets the world" do
    assert PolyglotWatcher.hello() == :world
  end
end
