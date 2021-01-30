defmodule PolyglotWatcher.ExampleLanguages.Blueberry.UserInput do
  alias PolyglotWatcher.UserInputBehaviour

  @behaviour UserInputBehaviour

  @impl UserInputBehaviour
  def prefix, do: "blueb"

  @impl UserInputBehaviour
  def usage, do: [{:red, "how to use blueb"}]

  # def starting_state, do: {:blueb, %{plant: :bush, colour: :blue, harvest: false, nom: false}}

  @impl UserInputBehaviour
  def determine_actions(user_input, server_state) do
    user_input
    |> String.split(prefix(), trim: true)
    |> Enum.map(&String.trim/1)
    |> case do
      ["harvest"] -> {:ok, {[{:puts, "harvest"}], put_in(server_state, [:blueb, :harvest], true)}}
      ["nom"] -> {:ok, {[{:puts, "nom"}], put_in(server_state, [:blueb, :nom], true)}}
      _ -> :no_actions
    end
  end
end
