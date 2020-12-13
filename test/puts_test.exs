defmodule PolyglotWatcher.PutsTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias PolyglotWatcher.Puts

  describe "on_new_line/1" do
    test "given only one string arg, prints the colour in magenta" do
      assert capture_io(fn -> Puts.on_new_line("my magenta message") end) ==
               "\e[35mmy magenta message\e[0m\n"
    end

    test "given a list of {colour, message} tuples, prints in multicolours" do
      assert capture_io(fn ->
               Puts.on_new_line([{:magenta, "magenta"}, {:red, "red"}, {:green, "green"}])
             end) == "\e[35mmagenta\e[0m\e[31mred\e[0m\e[32mgreen\e[0m\n"
    end

    test "can accept multiple styles" do
      assert capture_io(fn ->
               Puts.on_new_line([{[:magenta, :strikethrough], "magenta"}])
             end) == "\e[35m\e[9mmagenta\e[0m\n"
    end
  end

  describe "on_new_line/2" do
    test "can print in the supported colours" do
      assert capture_io(fn -> Puts.on_new_line("my magenta message", :magenta) end) ==
               "\e[35mmy magenta message\e[0m\n"

      assert capture_io(fn -> Puts.on_new_line("my red message", :red) end) ==
               "\e[31mmy red message\e[0m\n"

      assert capture_io(fn -> Puts.on_new_line("my green message", :green) end) ==
               "\e[32mmy green message\e[0m\n"

      assert capture_io(fn ->
               Puts.on_new_line("my magenta message", :magenta)
               Puts.on_new_line("my magenta message", :magenta)
             end) == "\e[35mmy magenta message\e[0m\n\e[35mmy magenta message\e[0m\n"
    end

    test "raises given a bad colour" do
      assert_raise RuntimeError, fn -> Puts.on_new_line("my magenta message", :jank) end
    end
  end

  describe "on_previous_line/1" do
    test "given only one string arg, overwrites the previous line in magenta" do
      assert capture_io(fn ->
               IO.puts("hello dave")
               Puts.on_previous_line("my magenta message")
             end) == "hello dave\n\e[1A\e[K\e[35mmy magenta message\e[0m\n"
    end

    test "given a list of {colour, message} tuples, prints in multicolours" do
      assert capture_io(fn ->
               IO.puts("hello dave")
               Puts.on_previous_line([{:magenta, "magenta"}, {:red, "red"}, {:green, "green"}])
             end) == "hello dave\n\e[1A\e[K\e[35mmagenta\e[0m\e[31mred\e[0m\e[32mgreen\e[0m\n"
    end
  end

  describe "on_previous_line/2" do
    test "can print in the supported colours" do
      assert capture_io(fn ->
               IO.puts("hello dave")
               Puts.on_previous_line("my magenta message", :magenta)
             end) == "hello dave\n\e[1A\e[K\e[35mmy magenta message\e[0m\n"

      assert capture_io(fn ->
               IO.puts("hello dave")
               Puts.on_previous_line("my red message", :red)
             end) == "hello dave\n\e[1A\e[K\e[31mmy red message\e[0m\n"

      assert capture_io(fn ->
               IO.puts("but my name's rodney")
               Puts.on_previous_line("my green message", :green)
             end) == "but my name's rodney\n\e[1A\e[K\e[32mmy green message\e[0m\n"

      assert capture_io(fn ->
               IO.puts("only you call me dave")
               Puts.on_previous_line("my magenta message", :magenta)
               Puts.on_previous_line("my magenta message", :magenta)
             end) ==
               "only you call me dave\n\e[1A\e[K\e[35mmy magenta message\e[0m\n\e[1A\e[K\e[35mmy magenta message\e[0m\n"
    end

    test "raises given a bad colour" do
      assert_raise RuntimeError, fn -> Puts.on_previous_line("my magenta message", :jank) end
    end
  end
end
