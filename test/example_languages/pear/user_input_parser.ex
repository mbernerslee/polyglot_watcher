defmodule PolyglotWatcher.ExampleLanguages.Pear.UserInput do
  alias PolyglotWatcher.UserInputBehaviour

  @behaviour UserInputBehaviour

  @impl UserInputBehaviour
  def prefix, do: "pear"

  @impl UserInputBehaviour
  def usage, do: [{:green, "how to use pear"}]

  #def starting_state do
  #  {:pear, %{juicy: true, tasty: true, pick: false, eat: false, peel: false}}
  #end

  @impl UserInputBehaviour
  def determine_actions(user_input, server_state) do
    user_input
    |> String.split(prefix(), trim: true)
    |> Enum.map(&String.trim/1)
    |> case do
      ["pick"] -> {:ok, {[{:puts, "pick"}], put_in(server_state, [:pear, :pick], true)}}
      ["eat"] -> {:ok, {[{:puts, "eat"}], put_in(server_state, [:pear, :eat], true)}}
      ["peel"] -> {:ok, {%{run: [{:puts, "peel"}]}, put_in(server_state, [:pear, :peel], true)}}
      _ -> :error
    end
  end
end
