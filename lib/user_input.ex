defmodule PolyglotWatcher.UserInput do
  def determine_actions(server_state, user_input) do
    case String.trim(user_input) do
      "exf" ->
        IO.puts("sorry, i didnt understand that")

      _ ->
        IO.puts("sorry, i didnt understand that")
    end

    server_state
  end
end
