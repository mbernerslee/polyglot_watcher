# PolyglotWatcher

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
Any detected save to `.ex` or `.exs` files to trigger a test run will run the corresponding test. e.g.
- saving `lib/my/cool/code.ex` will trigger `mix test test/my/cool/code_test.exs`
- saving `test/my/cool/code_test.exs` will trigger `mix test test/my/cool/code_test.exs`

### Fix all Mode
`ex fa` will switch to this mode\
Only show the output from one failing test at a time, until all the tests pass.\
\
Runs a a sequence of `mix test` commands until all the tests pass.\
Stays at a particular step in the steps listened below, until a condition to trigger moving to the next step is reached.\
\
1. `mix test`
Does not show the full test output.
- on success, stops here
- on failure, runs step 2
2. `mix test /path/to/specific/failure_test.exs:23`
This step does show the full test output so that you can make the test pass.
Picks a failing test and runs it until it passes
Saving any elixir file will trigger this same test run until it passes
- on success, go to next step
- on failure, stays at this step
3. `mix test /path/to/specific/failure_test.exs`
Runs all the tests from the file in step 2
- on success, go to step 4
- on failure, go back to step 2 with a new failing test
4. `mix test mix test --failed --max-failures 1`
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

## License
Copyright © 2020 Matthew Berners-Lee mattbernerslee@gmail.com\
This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.
