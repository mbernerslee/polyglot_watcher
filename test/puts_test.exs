defmodule PolyglotWatcher.PutsTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias PolyglotWatcher.Puts

  describe "put/2" do
    test "all supported colours" do
      assert capture_io(fn -> Puts.put("my magenta message", :magenta) end) =~
               "my magenta message"

      assert capture_io(fn -> Puts.put("my red message", :red) end) =~ "my red message"
      assert capture_io(fn -> Puts.put("my green message", :green) end) =~ "my green message"
    end
  end

  describe "put/1" do
    test "puts the message in magenta" do
      magenta_output = capture_io(fn -> Puts.put("my message", :magenta) end)
      default_colour_output = capture_io(fn -> Puts.put("my message") end)

      assert magenta_output == default_colour_output
    end
  end
end
