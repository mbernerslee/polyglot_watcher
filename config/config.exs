import Config

config :polyglot_watcher, executor: PolyglotWatcher.Executor.Real
config :polyglot_watcher, listen_for_user_input: true

import_config "#{Mix.env()}.exs"
