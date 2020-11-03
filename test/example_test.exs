defmodule PolyglotWatcher.ExampleTest do
  use ExUnit.Case, async: true

  @moduledoc """
  this is here to test a different tests ability to run 'mix test test/example_test.exs'.
  meta!
  """

  test "mathematical equality" do
    assert 1 == 1
  end
end
