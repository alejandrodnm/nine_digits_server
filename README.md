# NineDigits

TCP server for reciving nine numbers/

## Asumptions

Clients will not sit idle, so connections will be close based on the TCP
implementation of the host machine.

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
