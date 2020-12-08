defmodule PolyglotWatcher.Puts do
  Enum.each(
    [
      {:magenta, IO.ANSI.magenta()},
      {:red, IO.ANSI.red()},
      {:green, IO.ANSI.green()}
    ],
    fn {colour, ansi_code} ->
      def put(message, unquote(colour)) do
        IO.puts(unquote(ansi_code) <> message <> IO.ANSI.reset())
      end

      def write(message, unquote(colour)) do
        IO.write(unquote(ansi_code) <> message <> IO.ANSI.reset())
      end
    end
  )

  def put(message), do: put(message, :magenta)

  # TODO add write tests
  def write(message), do: write(message, :magenta)
end
