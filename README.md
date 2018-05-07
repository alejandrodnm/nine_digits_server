# Nine Digits

**To view this document and the code documentation in html format open
`./doc/index.html`**

TCP server for receiving nine digits numbers

## Installation and Running

This project requires Elixir 1.6 and Erlang 20 to run (It could work with
Erlang >= 18 but it has only been tested with 20). In case you don't have any of
those installed the project has a Docker image and a Makefile to execute
`mix` tasks with Docker:

- **build**: creates the Docker image.
- **clean**: deletes the docker image.
- **run** - `mix do clean --only prod, run --no-halt`: executes the program.
- **tests** - `mix test`: runs the tests.
- **lint** - `mix do credo, format --check-formatted`: runs code checks with
credo and the elixir formatter.
- **coverage** - `mix coveralls`: runs the tests and displays the code coverage.
- **coverage-html** - `mix coveralls.html`: generates the html page with detail
coverage in the `./cover` directory.
- **type-check** - `mix dialyzer`: runs the type check with `dialyzer`. The
- first time it is run it takes a couple of minutes to build the Persistent
Lookup Table (PLT), but they should be already included in the `_build` directory.
- **docs** - `mix docs`: generates the html documentation.

## Asumptions

Clients will not sit idle, so connections will be close based on the TCP
implementation of the host machine.

### Resilience
Uses dets instead of ets in order to restore the state of the run if the application
crashes.

## Installation

Elixir 1.6

mix compile

## Running

```
mix run --no-halt
```

## Configuration

The configuration for the port, ip (if the server has multiple interfaces) and
the number of concurrent connections to accept can be set in `config/config.ex`.

## Testing

To run dialyzer for type checking

```
mix dialyzer
```

Running unittests

```
mix test
```

Running unnittests with coveraga

```
mix coveralls
```
