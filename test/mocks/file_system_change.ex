defmodule PolyglotWatcher.Mocks.FileSystemChange do
  def determine_language_module(file_path, server_state) do
    if file_path =~ "magic_file_system_change_name" do
      {:arbitrary, file_path, server_state}
    else
      {:noop, server_state}
    end
  end
end
