defmodule PolyglotWatcher.Echo do
  @red "31"
  @pink "35"
  @yellow "33"
  @green "32"

  def red(message), do: wrap_message_in_colour(message, @red)
  def pink(message), do: wrap_message_in_colour(message, @pink)
  def yellow(message), do: wrap_message_in_colour(message, @yellow)
  def green(message), do: wrap_message_in_colour(message, @green)

  defp wrap_message_in_colour(message, colour) do
    ["-e", "\e[#{colour}m#{message}\e[39m"]
  end
end
