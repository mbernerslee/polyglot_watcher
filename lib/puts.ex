defmodule PolyglotWatcher.Puts do
  @styles %{
    magenta: IO.ANSI.magenta(),
    light_magenta: IO.ANSI.light_magenta(),
    light_green: IO.ANSI.light_green(),
    green: IO.ANSI.green(),
    red: IO.ANSI.red(),
    cyan: IO.ANSI.cyan(),
    light_cyan: IO.ANSI.light_cyan(),
    white: IO.ANSI.white(),
    light_white: IO.ANSI.light_white(),
    yellow: IO.ANSI.yellow(),
    black_on_yellow: IO.ANSI.black() <> IO.ANSI.yellow_background(),
    black_on_cyan: IO.ANSI.black() <> IO.ANSI.cyan_background(),
    italic: IO.ANSI.italic(),
    bright: IO.ANSI.bright()
  }

  @overwrite_previous_line_code "\e[1A\e[K"

  def on_new_line(message, style) do
    style |> build(message) |> IO.puts()
  end

  def on_new_line(messages) when is_list(messages) do
    messages
    |> build_multicoloured("")
    |> IO.puts()
  end

  def on_new_line(message), do: on_new_line(message, :magenta)

  def on_previous_line(message, style) do
    IO.puts(@overwrite_previous_line_code <> build(style, message))
  end

  def on_previous_line(messages) when is_list(messages) do
    IO.puts(@overwrite_previous_line_code <> build_multicoloured(messages, ""))
  end

  def on_previous_line(message), do: on_previous_line(message, :magenta)

  defp build_multicoloured([], acc), do: acc

  defp build_multicoloured([{style, message} | rest], acc) do
    build_multicoloured(rest, acc <> build(style, message))
  end

  defp build(style, message) do
    ansi_code = @styles[style]

    if ansi_code do
      @styles[style] <> message <> IO.ANSI.reset()
    else
      raise "I don't recognise the style '#{style}'"
    end
  end
end
