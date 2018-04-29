# NineDigits

TCP server for reciving nine numbers

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
