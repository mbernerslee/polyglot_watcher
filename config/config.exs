import Config

config :polyglot_watcher, executor: PolyglotWatcher.Executor.Real

import_config "#{Mix.env()}.exs"
