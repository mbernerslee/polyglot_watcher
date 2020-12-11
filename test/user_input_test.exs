defmodule FakeLanguage.Pear do
  alias PolyglotWatcher.UserInputParser

  @behaviour UserInputParser

  @impl UserInputParser
  def prefix, do: "pear"

  @impl UserInputParser
  def usage, do: "how to use pear"

  @impl UserInputParser
  def determine_actions(user_input, server_state) do
    user_input
    |> String.split(prefix(), trim: true)
    |> Enum.map(&String.trim/1)
    |> case do
      ["pick"] -> {:ok, {[{:puts, "pick"}], Map.put(server_state, :pick, true)}}
      ["eat"] -> {:ok, {[{:puts, "eat"}], Map.put(server_state, :eat, true)}}
      _ -> :error
    end
  end
end

defmodule FakeLanguage.Blueberry do
  alias PolyglotWatcher.UserInputParser

  @behaviour UserInputParser

  @impl UserInputParser
  def prefix, do: "blueb"

  @impl UserInputParser
  def usage, do: "how to use blueb"

  @impl UserInputParser
  def determine_actions(user_input, server_state) do
    user_input
    |> String.split(prefix(), trim: true)
    |> Enum.map(&String.trim/1)
    |> case do
      ["harvest"] -> {:ok, {[{:puts, "harvest"}], Map.put(server_state, :harvest, true)}}
      ["nom"] -> {:ok, {[{:puts, "nom"}], Map.put(server_state, :nom, true)}}
      _ -> :error
    end
  end
end

defmodule PolyglotWatcher.UserInputTest do
  use ExUnit.Case, async: true
  alias PolyglotWatcher.{ServerStateBuilder, UserInput}
  alias FakeLanguage.{Pear, Blueberry}

  @fake_languages [Pear, Blueberry]

  describe "determine_actions/3" do
    test "when given language user_input modules, returns any actions from them which can be determined" do
      server_state = ServerStateBuilder.build()

      result = UserInput.determine_actions("pear pick\n", server_state, @fake_languages)
      assert {[{:puts, "pick"}], %{pick: true}} = result

      result = UserInput.determine_actions("blueb harvest\n", server_state, @fake_languages)
      assert {[{:puts, "harvest"}], %{harvest: true}} = result

      result = UserInput.determine_actions("pear eat\n", server_state, @fake_languages)
      assert {[{:puts, "eat"}], %{eat: true}} = result

      result = UserInput.determine_actions("blueb nom\n", server_state, @fake_languages)
      assert {[{:puts, "nom"}], %{nom: true}} = result
    end

    test "when given something that's not understood at all, prints the usage" do
      server_state = ServerStateBuilder.build()

      usage = UserInput.usage(@fake_languages)

      result = UserInput.determine_actions("pear nonsense\n", server_state, @fake_languages)
      assert {[{:puts, ^usage}], ^server_state} = result

      result = UserInput.determine_actions("blueb nonsense\n", server_state, @fake_languages)
      assert {[{:puts, ^usage}], ^server_state} = result

      result = UserInput.determine_actions("some nonesense\n", server_state, @fake_languages)
      assert {[{:puts, ^usage}], ^server_state} = result
    end
  end

  describe "usage/1" do
    test "returns the usage detailed in all language modules" do
      usage = UserInput.usage(@fake_languages)

      assert usage ==
               "Usage\n\n" <>
                 "how to use pear\n\n" <>
                 "how to use blueb\n" <>
                 "Any unrecocogised input - prints this message"
    end
  end

  describe "parse/2" do
    test "returns the string after the prefix" do
      assert UserInput.parse("ex fa", "ex") == {:ok, "fa"}
      assert UserInput.parse("ex exfa", "ex") == {:ok, "exfa"}
      assert UserInput.parse("ex ex fa", "ex") == {:ok, "ex fa"}
      assert UserInput.parse("ex test/path_test.exs", "ex") == {:ok, "test/path_test.exs"}
    end

    test "errors when there's no at the start, or if there's no space" do
      assert UserInput.parse("nope", "ex") == :error
      assert UserInput.parse("nopex", "ex") == :error
      assert UserInput.parse("exhello", "ex") == :error
      assert UserInput.parse("nope ex nope", "ex") == :error
      assert UserInput.parse("nope ex", "ex") == :error
    end
  end
end
