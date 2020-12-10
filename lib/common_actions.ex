defmodule PolyglotWatcher.CommonActions do
  alias PolyglotWatcher.Puts

  # TODO write it into places

  @chars ["|", "/", "-", "\\"]
  @char_count length(@chars)

  def spin_while(fun, previous_line) do
    spinner_pid = spinner(previous_line)
    result = fun.()
    Process.exit(spinner_pid, :kill)
    result
  end

  defp spinner(previous_line), do: spawn(fn -> spin(previous_line) end)

  defp spin(previous_line), do: spin(0, previous_line)

  defp spin(char_index, previous_line) do
    char = Enum.at(@chars, rem(char_index, @char_count))
    updated_previous_line = previous_line ++ [{:green, "#{char}"}]
    Puts.on_previous_line(updated_previous_line)
    :timer.sleep(50)
    spin(char_index + 1, previous_line)
  end
end
