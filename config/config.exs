import Config

config :polyglot_watcher, executor: PolyglotWatcher.Executor.Real
config :polyglot_watcher, languages: PolyglotWatcher.Languages
config :polyglot_watcher, file_system_change: PolyglotWatcher.FileSystemChange
config :polyglot_watcher, listen_for_user_input: true

import_config "#{Mix.env()}.exs"
