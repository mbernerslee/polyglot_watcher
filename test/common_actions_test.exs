defmodule PolyglotWatcher.CommonActionsTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias PolyglotWatcher.CommonActions
  alias PolyglotWatcher.Puts

  describe "spin_while/1" do
    test "runs the given function while printing a spinner on the screen" do
      io =
        assert capture_io(fn ->
                 Puts.on_new_line("hello")
                 CommonActions.spin_while(fn -> :timer.sleep(20) end, [{:magenta, "hello"}])
               end)

      assert io =~ "|"
      assert io =~ "hello"
    end
  end
end
