defmodule PolyglotWatcher.Elm.Language do
  alias PolyglotWatcher.LanguageBehaviour
  alias PolyglotWatcher.Elm.Actions
  @behaviour LanguageBehaviour

  @elm ".elm"
  @main "Main.elm"
  @json "elm.json"

  @impl LanguageBehaviour
  def file_extensions do
    [@elm]
  end

  @impl LanguageBehaviour
  def starting_state do
    {:elm, %{mode: :default}}
  end

  @impl LanguageBehaviour
  def determine_actions(file, server_state) do
    path = Path.dirname(file.file_path)

    actions =
      case find_elm_json_and_main(path) do
        {:ok, {elm_json_path, elm_main_path}} ->
          %{
            run: [
              {:cd, elm_json_path},
              {:puts, "Running elm make #{elm_json_path}/#{elm_main_path}"},
              {:module_action, Actions, {:make, elm_main_path}}
            ],
            next: %{fallback: %{run: [{:run_sys_cmd, "tput", ["reset"]}, :reset_dir]}}
          }

        _ ->
          [
            {:puts,
             [
               {:red,
                "I could not find a corresponding elm.json and / or Main.elm file(s) for the file you saved:"}
             ]},
            {:puts, [{:red, file.file_path}]}
          ]
      end

    {actions, server_state}
  end

  defp find_elm_json_and_main(path) do
    cwd = File.cwd!()
    path = Path.join(cwd, path)

    find_elm_json_and_main(%{json: nil, main: nil}, cwd, path)
  end

  defp find_elm_json_and_main(acc, cwd, cwd) do
    continuation_fun = fn _ -> :error end
    found_them_yet(acc, cwd, continuation_fun)
  end

  defp find_elm_json_and_main(acc, cwd, path) do
    continuation_fun = fn acc -> do_find_elm_json_and_main(acc, cwd, path) end
    found_them_yet(acc, cwd, continuation_fun)
  end

  defp do_find_elm_json_and_main(acc, cwd, path) do
    files = File.ls!(path)

    acc =
      acc
      |> add_main(path, files)
      |> add_json(path, files)

    path =
      path
      |> Path.split()
      |> Enum.reverse()
      |> tl()
      |> Enum.reverse()
      |> Path.join()

    find_elm_json_and_main(acc, cwd, path)
  end

  defp found_them_yet(acc, cwd, continuation_fun) do
    if acc.json && acc.main do
      {:ok, {Path.relative_to(acc.json, cwd), Path.relative_to(acc.main, acc.json)}}
    else
      continuation_fun.(acc)
    end
  end

  defp add_main(acc, path, files) do
    if Enum.member?(files, @main) do
      %{acc | main: Path.join(path, @main)}
    else
      acc
    end
  end

  defp add_json(acc, path, files) do
    if Enum.member?(files, @json) do
      %{acc | json: path}
    else
      acc
    end
  end
end
