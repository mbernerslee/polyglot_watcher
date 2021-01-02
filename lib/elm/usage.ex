defmodule PolyglotWatcher.Elm.Usage do
  def usage do
    [
      {:yellow, "# Elm\n\n"},
      {:yellow, "## Command line input\n\n"},
      {:white, "  • "},
      {:white, "none supported yet"},
      {:white, "\n\n"},
      {:yellow, "## Watcher Modes\n\n"},
      {:bright, "default mode"},
      {:white, "\n"},
      {:white, "  "},
      {:green, "src/DoStuff.elm"},
      {:white, " is saved        -> runs "},
      {:green, "elm make src/Main.elm"},
      {:white, "\n\n"}
    ]
  end
end
