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
    end
  )

  def put(message), do: put(message, :magenta)
end
