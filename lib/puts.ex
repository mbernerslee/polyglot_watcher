defmodule PolyglotWatcher.Puts do
  use GenServer
  # TODO add write tests, this module is missing many

  @process_name :puts

  @default_options [name: @process_name]

  def child_spec do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [@default_options]}
    }
  end

  def start_link(genserver_options \\ @default_options) do
    GenServer.start_link(__MODULE__, [], genserver_options)
  end

  @impl true
  def init(_) do
    {:ok, %{current_line: []}}
  end

  @impl true
  def handle_cast({:put, line}, state) do
    {:noreply, %{state | current_line: line}}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state.current_line, state}
  end

  defp get_genserver_current_line(pid) do
    GenServer.call(pid, :get)
  end

  defp put_genserver_state(current_line, pid) do
    GenServer.cast(pid, {:put, current_line})
    current_line
  end

  defp append_genserver_state(suffix, pid) do
    put_genserver_state(get_genserver_current_line(pid) ++ [suffix], pid)
  end

  defp appendfully_overwrite_genserver_state({ansi_code, chars}, pid) do
    current_line = get_genserver_current_line(pid)
    current_line = build_appendful_overwrite(current_line, ansi_code, chars)
    put_genserver_state(current_line, pid)
  end

  defp build_appendful_overwrite(current_line, ansi_code, suffix) do
    old_line =
      current_line
      |> Enum.reverse()
      |> Enum.map(fn {ansi_code, chars} ->
        {ansi_code, chars |> String.graphemes() |> Enum.reverse()}
      end)

    suffix =
      suffix
      |> String.graphemes()
      |> Enum.reverse()

    acc = %{
      new_line: [],
      next_new_line_member: :go_next,
      suffix_acc: {ansi_code, []},
      suffix: suffix,
      old_line: old_line
    }

    build_appendful_overwrite(acc)
  end

  defp build_appendful_overwrite(
         %{next_new_line_member: :go_next, old_line: [{ansi_code, chars} | rest]} = acc
       ) do
    acc = %{acc | next_new_line_member: {ansi_code, chars, []}, old_line: rest}
    build_appendful_overwrite(acc)
  end

  defp build_appendful_overwrite(%{suffix: [], next_new_line_member: :go_next} = acc) do
    %{
      new_line: new_line,
      suffix_acc: {ansi_code, suffix_acc},
      old_line: old_line
    } = acc

    ([{ansi_code, suffix_acc} | new_line] ++ old_line)
    |> Enum.map(fn {ansi_code, chars} ->
      {ansi_code, chars |> Enum.reverse() |> Enum.join()}
    end)
    |> Enum.reverse()
  end

  defp build_appendful_overwrite(%{suffix: []} = acc) do
    %{
      new_line: new_line,
      next_new_line_member: {this_ansi_code, remaining, _replaced},
      suffix_acc: {ansi_code, suffix_acc},
      old_line: old_line
    } = acc

    ([{ansi_code, suffix_acc}, {this_ansi_code, remaining} | new_line] ++ old_line)
    |> Enum.map(fn {ansi_code, chars} ->
      {ansi_code, chars |> Enum.reverse() |> Enum.join()}
    end)
    |> Enum.reverse()
  end

  defp build_appendful_overwrite(acc) do
    %{
      next_new_line_member: {this_ansi_code, remaining, _replaced},
      suffix_acc: {ansi_code, suffix_acc},
      suffix: suffix
    } = acc

    %{to_add: to_add, remaining: remaining, replaced: more_replaced, suffix: suffix} =
      chars_to_add(remaining, suffix)

    acc = %{acc | suffix_acc: {ansi_code, suffix_acc ++ to_add}, suffix: suffix}

    acc =
      case {remaining, suffix} do
        {[], []} ->
          next_new_line_member = :go_next
          %{acc | next_new_line_member: next_new_line_member}

        {remaining, []} ->
          addition = more_replaced |> Enum.reverse() |> Enum.join()
          next_new_line_member = {this_ansi_code, remaining, addition}
          %{acc | next_new_line_member: next_new_line_member}

        {[], _suffix} ->
          next_new_line_member = :go_next
          %{acc | next_new_line_member: next_new_line_member}
      end

    build_appendful_overwrite(acc)
  end

  defp chars_to_add(chars, suffix), do: chars_to_add(%{to_add: [], replaced: []}, chars, suffix)

  defp chars_to_add(acc, chars, []) do
    %{
      to_add: Enum.reverse(acc.to_add),
      replaced: Enum.reverse(acc.replaced),
      remaining: chars,
      suffix: []
    }
  end

  defp chars_to_add(acc, [], suffix) do
    %{
      to_add: Enum.reverse(acc.to_add),
      replaced: Enum.reverse(acc.replaced),
      remaining: [],
      suffix: suffix
    }
  end

  defp chars_to_add(acc, [replaced | chars], [char_to_add | suffix]) do
    acc = %{acc | to_add: [char_to_add | acc.to_add], replaced: [replaced | acc.replaced]}
    chars_to_add(acc, chars, suffix)
  end

  defp prepend_genserver_state(prefix, pid) do
    current_line = [prefix | get_genserver_current_line(pid)]
    GenServer.cast(pid, {:put, current_line})
    current_line
  end

  defp write(line), do: line |> build_puts("") |> IO.write()

  defp puts(line), do: line |> build_puts("") |> IO.puts()

  defp overwrite(line), do: IO.write("\r#{build_puts(line, "")}")

  defp build_puts([], acc) do
    acc
  end

  defp build_puts({ansi_code, chars}, acc) do
    build_puts([{ansi_code, chars}], acc)
  end

  defp build_puts([{ansi_code, chars} | line], acc) do
    acc = acc <> ansi_code <> chars <> IO.ANSI.reset()
    build_puts(line, acc)
  end

  def on_new_line(message, colour, pid \\ @process_name)
  def append(message, colour, pid \\ @process_name)
  def appendfully_overwrite(message, colour, pid \\ @process_name)
  def prepend(message, colour, pid \\ @process_name)

  Enum.each(
    [
      {:magenta, IO.ANSI.magenta()},
      {:red, IO.ANSI.red()},
      {:green, IO.ANSI.green()}
    ],
    fn {colour, ansi_code} ->
      def on_new_line(message, unquote(colour), pid) do
        [{unquote(ansi_code), message}]
        |> put_genserver_state(pid)
        |> puts()
      end

      def append(suffix, unquote(colour), pid) do
        suffix = {unquote(ansi_code), suffix}
        append_genserver_state(suffix, pid)
        write(suffix)
      end

      def appendfully_overwrite(suffix, unquote(colour), pid) do
        {unquote(ansi_code), suffix}
        |> appendfully_overwrite_genserver_state(pid)
        |> overwrite()
      end

      def prepend(prefix, unquote(colour), pid) do
        suffix = {unquote(ansi_code), prefix}
        current_line = prepend_genserver_state(suffix, pid)
        overwrite(current_line)
      end
    end
  )
end
