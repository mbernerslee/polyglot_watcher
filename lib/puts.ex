defmodule PolyglotWatcher.Puts do
  @colours %{
    magenta: IO.ANSI.magenta(),
    red: IO.ANSI.red(),
    green: IO.ANSI.green()
  }

  @overwrite_previous_line_code "\e[1A\e[K"

  def on_new_line(message, colour) do
    colour |> build(message) |> IO.puts()
  end

  def on_new_line(messages) when is_list(messages) do
    messages
    |> build_multicoloured("")
    |> IO.puts()
  end

  def on_new_line(message), do: on_new_line(message, :magenta)

  def on_previous_line(message, colour) do
    IO.puts(@overwrite_previous_line_code <> build(colour, message))
  end

  def on_previous_line(messages) when is_list(messages) do
    IO.puts(@overwrite_previous_line_code <> build_multicoloured(messages, ""))
  end

  def on_previous_line(message), do: on_previous_line(message, :magenta)

  defp build_multicoloured([], acc), do: acc

  defp build_multicoloured([{colour, message} | rest], acc) do
    build_multicoloured(rest, acc <> build(colour, message))
  end

  defp build(colour, message) do
    ansi_code = @colours[colour]

    if ansi_code do
      @colours[colour] <> message <> IO.ANSI.reset()
    else
      raise "I don't recognise the colour '#{colour}'"
    end
  end
end
