defmodule PolyglotWatcher.PutsTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias PolyglotWatcher.Puts

  # TODO fix "mix test" being fundametally broken in this project!
  describe "on_new_line/2, append/2 and prepend/2" do
    test "puts all supported colours" do
      {:ok, pid} = Puts.start_link([])

      assert capture_io(fn -> Puts.on_new_line("my magenta message", :magenta, pid) end) =~
               "my magenta message"

      assert :sys.get_state(pid).current_line == [{"\e[35m", "my magenta message"}]

      assert capture_io(fn -> Puts.on_new_line("my red message", :red, pid) end) =~
               "my red message"

      assert :sys.get_state(pid).current_line == [{"\e[31m", "my red message"}]

      assert capture_io(fn -> Puts.on_new_line("my green message", :green, pid) end) =~
               "my green message"

      assert :sys.get_state(pid).current_line == [{"\e[32m", "my green message"}]

      assert capture_io(fn -> Puts.append(" APPEND ME", :red, pid) end) =~
               " APPEND ME"

      assert :sys.get_state(pid).current_line ==
               [{"\e[32m", "my green message"}, {"\e[31m", " APPEND ME"}]

      assert capture_io(fn -> Puts.prepend("PREPEND ME ", :magenta, pid) end) =~
               "PREPEND ME "

      assert :sys.get_state(pid).current_line ==
               [
                 {"\e[35m", "PREPEND ME "},
                 {"\e[32m", "my green message"},
                 {"\e[31m", " APPEND ME"}
               ]

      assert capture_io(fn -> Puts.appendfully_overwrite("XYZ", :green, pid) end) =~
               "XYZ"

      assert :sys.get_state(pid).current_line ==
               [
                 {"\e[35m", "PREPEND ME "},
                 {"\e[32m", "my green message"},
                 {"\e[31m", " APPEND"},
                 {"\e[32m", "XYZ"}
               ]

      assert capture_io(fn -> Puts.appendfully_overwrite("1234567891", :magenta, pid) end) =~
               "1234567891"

      assert :sys.get_state(pid).current_line ==
               [
                 {"\e[35m", "PREPEND ME "},
                 {"\e[32m", "my green message"},
                 {"\e[35m", "1234567891"}
               ]

      assert capture_io(fn ->
               Puts.appendfully_overwrite("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", :red, pid)
             end) =~
               "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

      assert :sys.get_state(pid).current_line ==
               [
                 {"\e[35m", "P"},
                 {"\e[31m", "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"}
               ]

      assert capture_io(fn ->
               Puts.appendfully_overwrite("BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", :green, pid)
             end) =~
               "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"

      assert :sys.get_state(pid).current_line ==
               [
                 {"\e[32m", "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"}
               ]

      assert capture_io(fn ->
               Puts.appendfully_overwrite("XYZ", :red, pid)
             end) =~
               "XYZ"

      assert :sys.get_state(pid).current_line ==
               [
                 {"\e[32m", "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"},
                 {"\e[31m", "XYZ"}
               ]
    end
  end
end
