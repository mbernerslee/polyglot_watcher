# PolyglotWatcher
A test watcher which can switch modes to change what it will run when different files are saved.

## Supported OS
  - Linux (presumably most distrubutions)
  - Mac (presumably most non-archaic versions)

## Prerequisites
  Have Elixir installed\
  https://elixir-lang.org/install.html

## Installation
```
git clone git@github.com:mbernerslee/polyglot_watcher.git
cd polyglot_watcher
./setup
```

Now you should be able to run `polyglot_watcher` from any directory

## Usage with an Elixir Project
- Run `polyglot_watcher` from the root of your project
- This will print the usage instructions on the screen, and explain how to switch watcher modes

### Default Mode
`ex d` will switch to this mode\
Any detected save to `.ex` or `.exs` files will trigger a test run for the corresponding test only\
- saving `lib/my/cool/code.ex` will trigger `mix test test/my/cool/code_test.exs`
- saving `test/my/cool/code_test.exs` will trigger `mix test test/my/cool/code_test.exs`

### Fix all Mode
`ex fa` will switch to this mode\
Only show the output from one failing test at a time, until all the tests pass.\
\
Runs a a sequence of `mix test` commands until all the tests pass.\
Stays at a particular step in the steps listened below, until a condition to trigger moving to the next step is reached.

1. `mix test`\
Does not show the full test output.
- on success, stops here
- on failure, runs step 2
2. `mix test /path/to/specific/failure_test.exs:23`\
This step does show the full test output so that you can make the test pass.
Picks a failing test and runs it until it passes
Saving any elixir file will trigger this same test run until it passes
- on success, go to next step
- on failure, stays at this step
3. `mix test /path/to/specific/failure_test.exs`\
Runs all the tests from the file in step 2
- on success, go to step 4
- on failure, go back to step 2 with a new failing test
4. `mix test mix test --failed --max-failures 1`\
Finds the next test failure
- on success, go to step 1
- on failure, go back to step 2 with a new failing test

### Fixed Mode (specifying a test path)
`ex test/my/favourite/test/path.exs` will switch to this mode\
Any detected save to `.ex` or `.exs` files will run only `ex test/my/favourite/test/path.exs`

### Fixed Mode
`ex f` will switch to this mode\
Any detected save to `.ex` or `.exs` files will run only `mix test <the last test that failed>`\
Switching to this mode will fail if the stored history of failing tests is empty

### Run 'mix test' as a one off
`ex a` will not switch mode.\
It will run `mix test` and show the full output on screen\

## Usage with an Elm Project
- Run `polyglot_watcher` from the root of your project

There's only one watcher mode for elm right now, which works as follosw:
Any detected save to `.elm` files will trigger `elm make path/to/the/corresponding/Main.elm`.
This will fail if 
- no corresponding `Main.elm` file is found
- no corresponding `elm.json` file is found

It tries to find the "corresponding `Main.elm`" file by traversing the file system, (starting from the saved file) to find `Main.elm` and `elm.json` to work out which directory `elm make <some/path/Main.elm>` should run from, and what `<some/path/Main.elm>` is. In the event that you've saved an elm module that's used in multiple elm apps (i.e. different Main.elm files), then it'll just arbitrarily choose the `Main.elm` file that it finds first. Work in progress!


## License
Copyright © 2020 Matthew Berners-Lee mattbernerslee@gmail.com\
This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.
